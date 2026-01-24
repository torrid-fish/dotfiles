#!/bin/bash

# =============================================================================
# ZSH + Starship + Oh-My-Zsh Auto Installation Script
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
# Install ZSH
# =============================================================================
install_zsh() {
    if command -v zsh &> /dev/null; then
        print_success "ZSH is already installed: $(zsh --version)"
        return 0
    fi

    print_info "Installing ZSH..."

    case $OS in
        ubuntu|debian|pop)
            sudo apt update
            sudo apt install -y zsh
            ;;
        fedora)
            sudo dnf install -y zsh
            ;;
        centos|rhel)
            sudo yum install -y zsh
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm zsh
            ;;
        macos)
            brew install zsh
            ;;
        *)
            print_error "Unsupported OS: $OS"
            print_info "Please install ZSH manually"
            return 1
            ;;
    esac

    print_success "ZSH installation complete: $(zsh --version)"
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
    if command -v starship &> /dev/null; then
        print_success "Starship is already installed: $(starship --version)"
        return 0
    fi

    print_info "Installing Starship..."

    # Use official installation script
    curl -sS https://starship.rs/install.sh | sh -s -- -y

    print_success "Starship installation complete"
}

# =============================================================================
# Setup Starship Configuration
# =============================================================================
setup_starship_config() {
    print_info "Setting up Starship configuration..."

    # Create ~/.config directory if it doesn't exist
    mkdir -p "$HOME/.config"

    # Copy starship.toml to ~/.config/
    if [[ -f "$SCRIPT_DIR/starship.toml" ]]; then
        cp "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
        print_success "Starship config copied to ~/.config/starship.toml"
    else
        print_warning "starship.toml not found, please configure manually"
    fi
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

    print_info "Do you want to set ZSH as the default shell? (y/n)"
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        local zsh_path=$(which zsh)
        
        # Ensure zsh is in /etc/shells
        if ! grep -q "$zsh_path" /etc/shells; then
            print_info "Adding $zsh_path to /etc/shells..."
            echo "$zsh_path" | sudo tee -a /etc/shells
        fi

        chsh -s "$zsh_path"
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
    echo "  ZSH + Starship + Oh-My-Zsh Setup Script"
    echo "=========================================="
    echo ""

    detect_os

    echo ""
    print_info "Starting installation..."
    echo ""

    install_zsh
    install_oh_my_zsh
    install_omz_plugins
    install_starship
    setup_starship_config
    setup_zshrc
    set_default_shell

    echo ""
    echo "=========================================="
    print_success "Installation complete!"
    echo "=========================================="
    echo ""
    print_info "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
    echo ""
}

main "$@"
