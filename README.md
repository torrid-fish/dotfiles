# Dotfiles

Dotfiles managed by [GNU Stow](https://www.gnu.org/software/stow/) and versioned with git. All configs live under `~/.config/` following the [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html) convention.

## Structure

Each top-level directory is a **stow package** that mirrors the target structure under `$HOME`:

```
dotfiles/
├── agents/       → ~/.agents/skills/* (cross-agent skills, read natively by pi & opencode)
├── bash/         → ~/.bashrc, ~/.bash_logout, ~/.profile
├── btop/         → ~/.config/btop/btop.conf
├── fcitx5/       → ~/.config/fcitx5/{config,profile,conf/*.conf}
├── gh/           → ~/.config/gh/config.yml
├── git/          → ~/.config/git/{config,commit-template,ignore}
├── pi/           → ~/.pi/agent/{prompts,extensions} (portable parts only)
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
| `agents` | Cross-agent skills in `~/.agents/skills/`: exa-agent, exa-search, tmux-pane-collab, ghidra, git-master, playwright-cli, convert-documents-to-markdown, antigravity-looker |
| `bash` | bashrc / profile / bash_logout |
| `btop` | System monitor config (btop 1.4+) |
| `fcitx5` | Input method: Boshiamy, Mozc, punctuation, shortcuts |
| `gh` | GitHub CLI aliases & preferences |
| `git` | Git settings, conventional commit template, global ignore |
| `pi` | pi coding agent: `/init` + `/review` prompt templates, `tok-speed-footer` extension (needs `npm install` in `~/.pi/agent/extensions/` once). `settings.json`/`models.json`/`auth.json` are machine-local — never stowed |
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

## Operating system support

**Tested on Ubuntu.** Everything beyond that depends on the package:

| Scope | Portability |
|---|---|
| `git` `gh` `starship` `tmux` `vim` `btop` | Cross-platform — work on any Unix (Linux, macOS) that has the tool and GNU Stow |
| `fcitx5` | Linux only (X11/Wayland input method framework) |
| `zsh` `bash` | Contain machine-specific PATH entries (`texlive/.../x86_64-linux`, a hardcoded LM Studio path, `/usr/local/go/bin`). Unknown paths are harmless no-ops elsewhere, but only meaningful on the author's Linux machines |
| `setup.sh` | Installer branches exist for apt/dnf/yum/pacman/apk/brew, but only apt has actually been tested |

macOS notes: the zsh configs will load, but the Linux-specific PATH entries are no-ops — prune them or move machine-specific bits into a gitignored `*.local` file.
