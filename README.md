# Dotfiles

Personal configuration repository. `~/.dotfiles` is the source of truth;
configuration files are deployed to their conventional home/XDG locations with
symbolic links.

## Layout

The repository root directly contains the configuration directories. There is
no extra `.config` directory inside the repository:

```text
~/.dotfiles/
├── .bashrc                 # linked to ~/.bashrc
├── .bash_logout            # linked to ~/.bash_logout
├── .profile                # linked to ~/.profile
├── zsh/                    # linked to ~/.config/zsh
├── git/                    # linked to ~/.config/git
├── tmux/                   # linked to ~/.config/tmux
├── vim/                    # linked to ~/.config/vim
├── btop/                   # linked to ~/.config/btop
├── fcitx5/                 # linked to ~/.config/fcitx5
├── gh/                     # linked to ~/.config/gh
├── starship.toml           # linked to ~/.config/starship.toml
└── setup.sh
```

## Install or deploy

```bash
git clone https://github.com/torrid-fish/dotfiles.git ~/.dotfiles
~/.dotfiles/setup.sh -y
```

The setup script may install missing tools, then creates symlinks. Existing
regular files are moved to a timestamped `.bak` path before replacement. It
does not overwrite repository files.

## Sensitive and generated files

Secrets and machine-specific overrides are intentionally not tracked:

- `zsh/secrets.zsh`
- `zsh/*.local`
- shell completion caches such as `.zcompdump*`

Create local secrets after deployment, for example:

```bash
vim ~/.config/zsh/secrets.zsh
chmod 600 ~/.config/zsh/secrets.zsh
```
