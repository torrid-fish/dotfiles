# Dotfiles

Dotfiles managed by [GNU Stow](https://www.gnu.org/software/stow/) and versioned with git. All configs live under `~/.config/` following the [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html) convention.

## Structure

Each top-level directory is a **stow package** that mirrors the target structure under `$HOME`:

```
dotfiles/
├── bash/         → ~/.bashrc, ~/.bash_logout, ~/.profile
├── btop/         → ~/.config/btop/btop.conf
├── fcitx5/       → ~/.config/fcitx5/{config,profile,conf/*.conf}
├── gh/           → ~/.config/gh/config.yml
├── git/          → ~/.config/git/{config,commit-template,ignore}
├── starship/     → ~/.config/starship.toml
├── tmux/         → ~/.config/tmux/tmux.conf
├── vim/          → ~/.config/vim/vimrc
├── zsh/          → ~/.zshenv, ~/.zshrc
└── setup.sh      → one-shot installer (installs stow, symlinks everything)
```

**Note on granularity:** directories containing runtime artifacts (e.g. `gh/hosts.yml` with login tokens, `tmux/plugins/`, `btop/themes/`, fcitx5 caches) are **not** symlinked as a whole — only the actual config files are, so junk and secrets never end up in this repo.

## Quick start (new machine)

```bash
git clone git@github.com:torrid-fish/dotfiles.git ~/Code/dotfiles
cd ~/Code/dotfiles
./setup.sh -y
```

The script will install stow if missing, back up any conflicting real files to `~/.dotfiles-backup/`, and symlink every package into `$HOME`.

## Manual stow usage

From the repo root:

```bash
stow -t ~ --restow git        # link / re-link one package
stow -t ~ -D git              # unlink one package
stow -t ~ --restow btop fcitx5 gh git starship tmux vim   # everything
./setup.sh --unstow           # unlink all packages
```

## Packages

| Package | Contents |
|---|---|
| `bash` | bashrc / profile / bash_logout |
| `btop` | System monitor config (btop 1.4+) |
| `fcitx5` | Input method: Boshiamy, Mozc, punctuation, shortcuts |
| `gh` | GitHub CLI aliases & preferences |
| `git` | Git settings, conventional commit template, global ignore |
| `starship` | Cross-shell prompt |
| `tmux` | Terminal multiplexer config (TPM plugins auto-bootstrap on first run) |
| `vim` | Vim 9.1+ with XDG-native vimrc |
| `zsh` | Zsh env, Oh-My-Zsh, per-tool PATH setup |

## Sensitive and machine-specific files

Secrets and per-machine overrides are intentionally not tracked (see `.gitignore`):

- `gh/hosts.yml` (login tokens) — only `config.yml` is symlinked
- `zsh/secrets.zsh` — create locally after deployment, source it from `.zshrc` if needed
- `*.local` — machine-local overrides
- Runtime caches (`plugins/`, `btop/themes/`, `.zcompdump*`, ...) stay as real files/dirs

## Supported Operating Systems

- Ubuntu / Debian / Pop!_OS
- Fedora
- CentOS / RHEL
- Arch / Manjaro
- Alpine Linux
- macOS
