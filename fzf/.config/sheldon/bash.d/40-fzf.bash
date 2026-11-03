# After mise activate so fd/eza are on PATH for FZF_*_COMMAND.
if [ -f "${XDG_CONFIG_HOME}/fzf/fzf.sh" ]; then
  . "${XDG_CONFIG_HOME}/fzf/fzf.sh"
fi

if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --bash)"
fi
