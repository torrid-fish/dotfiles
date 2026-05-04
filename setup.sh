#!/bin/bash

# =============================================================================
# Torridfish Dotfiles Setup Script
# All configs follow XDG Base Directory convention (~/.config/)
# =============================================================================

set -e  # Exit on error

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine if we need sudo (empty if running as root)
if [[ $EUID -eq 0 ]]; then
    SUDO=""
    IS_ROOT=true
else
    SUDO="sudo"
    IS_ROOT=false
fi

# Check for non-interactive mode (useful for Docker)
NON_INTERACTIVE=false
if [[ "$1" == "-y" ]] || [[ "$1" == "--yes" ]]; then
    NON_INTERACTIVE=true
fi

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# Check if command exists and is installed
# =============================================================================
is_installed() {
    local cmd="$1"
    if command -v "$cmd" &> /dev/null; then
        return 0
    fi
    return 1
}

# =============================================================================
# Get version of installed command
# =============================================================================
get_version() {
    local cmd="$1"
    if is_installed "$cmd"; then
        "$cmd" --version 2>&1 | head -n 1
    else
        echo "Not installed"
    fi
}

# =============================================================================
# Install package using appropriate package manager
# =============================================================================
install_package() {
    local package_name="$1"
    
    case $OS in
        ubuntu|debian|pop)
            $SUDO apt update
            $SUDO apt install -y "$package_name"
            ;;
        fedora)
            $SUDO dnf install -y "$package_name"
            ;;
        centos|rhel)
            $SUDO yum install -y "$package_name"
            ;;
        arch|manjaro)
            $SUDO pacman -S --noconfirm "$package_name"
            ;;
        alpine)
            $SUDO apk add --no-cache "$package_name"
            ;;
        macos)
            brew install "$package_name"
            ;;
        *)
            print_error "Unsupported OS: $OS"
            return 1
            ;;
    esac
}

# =============================================================================
# Detect Operating System
# =============================================================================
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
    print_info "Detected OS: $OS"
}

# =============================================================================
# Copy XDG config directory contents
# Copies all files from $SCRIPT_DIR/.config/$subdir/ to ~/.config/$subdir/
# Removes legacy dotfile from home if it exists (to avoid overriding XDG)
# =============================================================================
copy_xdg_config() {
    local subdir="$1"
    local legacy_files=("${@:2}")  # legacy home dotfiles to remove

    local src="$SCRIPT_DIR/.config/$subdir"
    local dst="$HOME/.config/$subdir"

    if [[ ! -d "$src" ]]; then
        print_warning "$subdir config not found in dotfiles, skipping"
        return 1
    fi

    mkdir -p "$dst"
    cp -r "$src"/* "$dst/" 2>/dev/null || true
    print_success "$subdir config copied to ~/.config/$subdir/"

    for legacy in "${legacy_files[@]}"; do
        if [[ -f "$HOME/$legacy" ]]; then
            mv "$HOME/$legacy" "$HOME/$legacy.bak"
            print_warning "Moved legacy ~/$legacy to ~/$legacy.bak (XDG config takes priority)"
        fi
    done

    return 0
}

# =============================================================================
# Install ZSH
# =============================================================================
install_zsh() {
    if is_installed zsh; then
        print_success "ZSH is already installed: $(get_version zsh)"
        return 0
    fi

    print_info "Installing ZSH..."
    install_package zsh
    print_success "ZSH installation complete: $(get_version zsh)"
}

# =============================================================================
# Install Oh-My-Zsh
# =============================================================================
install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_success "Oh-My-Zsh is already installed"
        return 0
    fi

    print_info "Installing Oh-My-Zsh..."

    # Use unattended mode, don't automatically switch shell
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    print_success "Oh-My-Zsh installation complete"
}

# =============================================================================
# Install Oh-My-Zsh Plugins
# =============================================================================
install_omz_plugins() {
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    print_info "Installing Oh-My-Zsh plugins..."

    # zsh-autosuggestions
    if [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        print_success "zsh-autosuggestions is already installed"
    else
        print_info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        print_success "zsh-autosuggestions installation complete"
    fi

    # zsh-syntax-highlighting
    if [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        print_success "zsh-syntax-highlighting is already installed"
    else
        print_info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        print_success "zsh-syntax-highlighting installation complete"
    fi

    # git plugin is built into Oh-My-Zsh, no additional installation needed
    print_success "git plugin is built into Oh-My-Zsh"
}

# =============================================================================
# Install Starship
# =============================================================================
install_starship() {
    if is_installed starship; then
        print_success "Starship is already installed: $(get_version starship)"
        return 0
    fi

    print_info "Installing Starship..."

    # Use official installation script
    curl -sS https://starship.rs/install.sh | sh -s -- -y

    print_success "Starship installation complete"
}

# =============================================================================
# Install Vim
# =============================================================================
install_vim() {
    if is_installed vim; then
        print_success "Vim is already installed: $(get_version vim)"
        return 0
    fi

    print_info "Installing Vim..."
    install_package vim
    print_success "Vim installation complete: $(get_version vim)"
}

# =============================================================================
# Install Tmux
# =============================================================================
install_tmux() {
    if is_installed tmux; then
        print_success "Tmux is already installed: $(get_version tmux)"
        return 0
    fi

    print_info "Installing Tmux..."
    install_package tmux
    print_success "Tmux installation complete: $(get_version tmux)"
}

# =============================================================================
# Install Tmux Plugin Manager (TPM)
# =============================================================================
install_tmux_plugins() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"

    print_info "Setting up Tmux Plugin Manager..."

    # Check if TPM is already installed
    if [[ -d "$tpm_dir" ]]; then
        print_success "Tmux Plugin Manager is already installed"
    else
        # Clone TPM repository
        if is_installed git; then
            print_info "Cloning Tmux Plugin Manager..."
            git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
            print_success "Tmux Plugin Manager cloned successfully"
        else
            print_warning "Git is not installed, cannot install Tmux Plugin Manager"
            print_info "Please install TPM manually: git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
            return 1
        fi
    fi

    # Install plugins by running TPM's install script
    if [[ -f "$tpm_dir/bin/install_plugins" ]]; then
        print_info "Installing Tmux plugins..."
        "$tpm_dir/bin/install_plugins"
        print_success "Tmux plugins installed successfully"
    else
        print_warning "TPM install script not found"
        print_info "Plugins will be installed when you start tmux and press the tmux prefix + I (capital I)"
    fi
}

# =============================================================================
# Setup Git Configuration (XDG: ~/.config/git/)
# =============================================================================
setup_git_config() {
    print_info "Setting up Git configuration..."
    copy_xdg_config git ".gitconfig" ".gitmessage.txt"
}

# =============================================================================
# Setup Starship Configuration (XDG: ~/.config/starship.toml)
# =============================================================================
setup_starship_config() {
    print_info "Setting up Starship configuration..."
    mkdir -p "$HOME/.config"

    if [[ -f "$SCRIPT_DIR/.config/starship.toml" ]]; then
        cp "$SCRIPT_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
        print_success "Starship config copied to ~/.config/starship.toml"
    else
        print_warning "starship.toml not found, please configure manually"
    fi
}

# =============================================================================
# Setup Vim Configuration (XDG: ~/.config/vim/)
# =============================================================================
setup_vim_config() {
    print_info "Setting up Vim configuration..."
    copy_xdg_config vim ".vimrc"
}

# =============================================================================
# Setup Tmux Configuration (XDG: ~/.config/tmux/)
# =============================================================================
setup_tmux_config() {
    print_info "Setting up Tmux configuration..."
    copy_xdg_config tmux ".tmux.conf"
}

# =============================================================================
# Setup fcitx5 Configuration (XDG: ~/.config/fcitx5/)
# =============================================================================
setup_fcitx5_config() {
    print_info "Setting up fcitx5 configuration..."
    copy_xdg_config fcitx5
}

# =============================================================================
# Setup btop Configuration (XDG: ~/.config/btop/)
# =============================================================================
setup_btop_config() {
    print_info "Setting up btop configuration..."
    copy_xdg_config btop
}

# =============================================================================
# Setup GitHub CLI Configuration (XDG: ~/.config/gh/)
# =============================================================================
setup_gh_config() {
    print_info "Setting up GitHub CLI configuration..."
    copy_xdg_config gh
}

# =============================================================================
# Setup .zshrc
# =============================================================================
setup_zshrc() {
    print_info "Setting up .zshrc..."

    local zshrc="$HOME/.zshrc"

    # Configure plugins
    if [[ -f "$zshrc" ]]; then
        # Check if plugins setting exists and update to our required plugins
        if grep -q "^plugins=" "$zshrc"; then
            # Backup original setting
            sed -i.bak 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$zshrc"
            print_success "Updated plugins configuration"
        else
            # Add plugins before source $ZSH/oh-my-zsh.sh
            sed -i.bak '/source \$ZSH\/oh-my-zsh.sh/i plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' "$zshrc"
            print_success "Added plugins configuration"
        fi
    fi

    # Check if starship init already exists
    if [[ -f "$zshrc" ]] && grep -q "starship init zsh" "$zshrc"; then
        print_success "Starship init already exists in .zshrc"
        return 0
    fi

    # Add starship init to the end of .zshrc
    echo '' >> "$zshrc"
    echo '# Starship prompt' >> "$zshrc"
    echo 'eval "$(starship init zsh)"' >> "$zshrc"

    print_success "Added Starship init to .zshrc"
}

# =============================================================================
# Set Default Shell
# =============================================================================
set_default_shell() {
    local current_shell=$(basename "$SHELL")

    if [[ "$current_shell" == "zsh" ]]; then
        print_success "ZSH is already the default shell"
        return 0
    fi

    # In non-interactive mode, automatically set ZSH as default
    if [[ "$NON_INTERACTIVE" == true ]]; then
        response="y"
    else
        print_info "Do you want to set ZSH as the default shell? (y/n)"
        read -r response
    fi

    if [[ "$response" =~ ^[Yy]$ ]]; then
        local zsh_path=$(which zsh)
        
        # Ensure zsh is in /etc/shells
        if [[ -f /etc/shells ]] && ! grep -q "$zsh_path" /etc/shells; then
            print_info "Adding $zsh_path to /etc/shells..."
            echo "$zsh_path" | $SUDO tee -a /etc/shells
        fi

        # Use chsh if available, otherwise modify passwd directly (for Docker)
        if is_installed chsh; then
            chsh -s "$zsh_path"
        else
            # For minimal Docker images without chsh
            $SUDO sed -i "s|$(whoami):.*:/bin/.*|$(whoami):x:$(id -u):$(id -g)::$HOME:$zsh_path|" /etc/passwd
        fi
        print_success "Default shell changed to ZSH"
        print_info "Please log out and log back in to apply changes"
    else
        print_info "Skipping default shell setup"
    fi
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo ""
    echo "=========================================="
    echo "  Torridfish Dotfiles Setup"
    echo "=========================================="
    echo ""

    detect_os

    if [[ "$IS_ROOT" == true ]]; then
        print_info "Running as root, sudo not required"
    fi

    if [[ "$NON_INTERACTIVE" == true ]]; then
        print_info "Running in non-interactive mode"
    fi

    echo ""
    print_info "Starting installation..."
    echo ""

    install_zsh
    install_oh_my_zsh
    install_omz_plugins
    install_starship
    install_vim
    install_tmux
    setup_git_config
    setup_starship_config
    setup_vim_config
    setup_tmux_config
    install_tmux_plugins
    setup_fcitx5_config
    setup_btop_config
    setup_gh_config
    setup_zshrc
    set_default_shell

    echo ""
    echo "=========================================="
    print_success "Installation complete!"
    echo "=========================================="
    echo ""
    print_info "All configs are installed to ~/.config/ (XDG Base Directory)"
    print_info "Legacy dotfiles (if found) backed up with .bak extension"
    print_info "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
    echo ""
}

main "$@"