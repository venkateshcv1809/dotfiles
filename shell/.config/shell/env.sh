# XDG base directory defaults
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# eza configuration
export EZA_CONFIG_DIR="${XDG_CONFIG_HOME}/eza"
export EZA_ICONS_AUTO="always"

# Mise shims take precedence
export PATH="$HOME/.local/share/mise/shims:$PATH"

# fzf theme and options
if [ -f "${XDG_CONFIG_HOME}/fzf/fzf.sh" ]; then
    . "${XDG_CONFIG_HOME}/fzf/fzf.sh"
fi

# fd color for terminal integrations
export FD_OPTIONS="--color=always"

# Default editor
export EDITOR="nvim"
export VISUAL="nvim"
