# Dotfiles

Automated setup script for a Zsh development environment following [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html) convention. All configs live under `~/.config/`.

## Features

- **Zsh Shell** - Modern shell with improved scripting capabilities
- **Oh-My-Zsh** - Zsh framework with plugin support (git, zsh-autosuggestions, zsh-syntax-highlighting)
- **Starship Prompt** - Fast, customizable cross-shell prompt
- **Git** - User settings, LFS, commit template, aliases (`sync`, `graph`)
- **Vim** - Optimized settings with habamax colorscheme
- **Tmux** - Terminal multiplexer with TPM and solarized theme
- **fcitx5** - Input method (Boshiamy, Mozc, shortcuts)
- **btop** - System monitor preferences
- **GitHub CLI** - gh preferences and aliases

## Installation

```bash
git clone https://github.com/torrid-fish/zsh_env.git
cd zsh_env
./setup.sh -y
```

## Configuration Files

All configs are stored under `.config/` and deployed to `~/.config/`:

| Repo Path | Deployed To | Notes |
|---|---|---|
| `.config/git/config` | `~/.config/git/config` | Git settings & aliases |
| `.config/git/commit-template` | `~/.config/git/commit-template` | Conventional commit template |
| `.config/vim/vimrc` | `~/.config/vim/vimrc` | Vim 9.1+ XDG native |
| `.config/tmux/tmux.conf` | `~/.config/tmux/tmux.conf` | tmux 3.1+ XDG native |
| `.config/starship.toml` | `~/.config/starship.toml` | Starship prompt |
| `.config/fcitx5/` | `~/.config/fcitx5/` | Input method config, profile, confs |
| `.config/btop/btop.conf` | `~/.config/btop/btop.conf` | System monitor |
| `.config/gh/config.yml` | `~/.config/gh/config.yml` | GitHub CLI |

Legacy dotfiles (`~/.gitconfig`, `~/.vimrc`, `~/.tmux.conf`, `~/.gitmessage.txt`) are automatically backed up with a `.bak` suffix if found, since they override the XDG paths.

## Supported Operating Systems

- Ubuntu / Debian / Pop!_OS
- Fedora
- CentOS / RHEL
- Arch / Manjaro
- Alpine Linux
- macOS