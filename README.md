# zsh_env
An automated setup script to install and configure a complete Zsh development environment with Starship prompt, Oh-My-Zsh plugins, and Vim configuration.

## Features
- **Zsh Shell** - Modern shell with improved scripting capabilities
- **Oh-My-Zsh** - Zsh framework with extensive plugin support
- **Plugins** - Pre-configured with:
  - `git` - Git aliases and utilities
  - `zsh-autosuggestions` - Command history suggestions
  - `zsh-syntax-highlighting` - Real-time syntax highlighting
- **Starship Prompt** - Fast, customizable cross-shell prompt
- **Vim Configuration** - Optimized Vim settings with habamax colorscheme
    - Vim habamax colorscheme is downloaded automatically with fallback to default theme
- The script automatically detects if running as root (useful for Docker containers)
- All installations are checked for existing packages to avoid re-installation

## Installation
```bash
git clone https://github.com/torrid-fish/zsh_env.git
cd zsh_env
./setup.sh -y
```

## Configuration Files
- **`starship.toml`** - Starship prompt configuration (copied to `~/.config/starship.toml`)
- **`.vimrc`** - Vim editor settings (copied to `~/.vimrc`)

## Supported Operating Systems
- Ubuntu / Debian / Pop!_OS
- Fedora
- CentOS / RHEL
- Arch / Manjaro
- Alpine Linux
- macOS
