# Keep standard system utilities available even if the inherited PATH is empty
# or contains only a machine-local entry.
path=("$HOME/.local/bin" "$HOME/.cargo/bin" /usr/local/bin /usr/bin /bin $path)
typeset -U path PATH

. "$HOME/.cargo/env"

# Secrets: separate file, mode 600. Here rather than .zshrc so non-interactive
# shells (ssh host 'cmd') get them too.
[ -f "$HOME/.config/zsh/secrets.zsh" ] && . "$HOME/.config/zsh/secrets.zsh"
