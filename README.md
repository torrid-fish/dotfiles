# zsh_env
An automated setup script to install and configure a complete Zsh development environment with Starship prompt, Oh-My-Zsh plugins, Vim, Tmux, and Git configuration.

## Features
- **Zsh Shell** - Modern shell with improved scripting capabilities
- **Oh-My-Zsh** - Zsh framework with extensive plugin support
- **Oh-My-Zsh Plugins** - Pre-configured with:
  - `git` - Git aliases and utilities
  - `zsh-autosuggestions` - Command history suggestions
  - `zsh-syntax-highlighting` - Real-time syntax highlighting
- **Starship Prompt** - Fast, customizable cross-shell prompt
- **Vim Configuration** - Optimized Vim settings with habamax colorscheme
- **Tmux Configuration** - Terminal multiplexer with TPM (Tmux Plugin Manager)
  - Pre-configured plugins: tmux-sensible, tmux-colors-solarized
  - Plugins automatically installed via TPM
- **Git Configuration** - User settings, commit message template, and aliases
- **Docker Compatible** - Script automatically detects if running as root
- **Smart Installation** - All packages checked for existing installations to avoid re-installation

## Installation
```bash
git clone https://github.com/torrid-fish/zsh_env.git
cd zsh_env
./setup.sh -y
```

## Configuration Files
The setup automatically copies and configures these files:
- **`starship.toml`** - Starship prompt configuration (→ `~/.config/starship.toml`)
- **`.vimrc`** - Vim editor settings (→ `~/.vimrc`)
- **`.tmux.conf`** - Tmux terminal multiplexer config (→ `~/.tmux.conf`)
- **`.gitconfig`** - Git user settings and aliases (→ `~/.gitconfig`)
- **`.gitmessage.txt`** - Conventional commit message template (→ `~/.gitmessage.txt`)

## Supported Operating Systems

- Ubuntu / Debian / Pop!_OS
- Fedora
- CentOS / RHEL
- Arch / Manjaro
- Alpine Linux
- macOS
