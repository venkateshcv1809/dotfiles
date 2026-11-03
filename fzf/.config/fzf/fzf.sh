#!/usr/bin/env sh

# Catppuccin Mocha colors
if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/themes/catppuccin-fzf-mocha.sh" ]; then
    . "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/themes/catppuccin-fzf-mocha.sh"
fi

# Prompt at the top, window not full screen
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
  --ansi \
  --height=80% \
  --layout=reverse \
  --border=rounded"

# Fast file search via fd. Color is scoped to fzf, not to every fd invocation.
if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git --color=always"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fd --type d --hidden --strip-cwd-prefix --exclude .git --color=always"
fi

# Preview the highlighted file
if command -v bat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range :500 {}'"
fi

# Preview the highlighted directory.
if command -v eza >/dev/null 2>&1; then
    export FZF_ALT_C_OPTS="--preview 'eza --tree --level=3 --group-directories-first --icons=always --color=always {}'"
fi
