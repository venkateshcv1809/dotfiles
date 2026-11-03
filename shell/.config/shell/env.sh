# XDG base directory defaults
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export PATH="${HOME}/.local/bin:${PATH}"

# eza configuration
export EZA_CONFIG_DIR="${XDG_CONFIG_HOME}/eza"

# Cargo's environment was previously loaded from the Zsh startup file.
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# Interactive shells use `mise activate` from bashrc/zshrc.
# Non-interactive callers that source this file get shims only.
case "$-" in
    *i*) ;;
    *)
        export PATH="${HOME}/.local/share/mise/shims:${PATH}"
        ;;
esac

# Default editor
export EDITOR="nvim"
export VISUAL="nvim"
