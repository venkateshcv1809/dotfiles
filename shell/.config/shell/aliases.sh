# POSIX Aliases shared across Bash and Zsh

# bat (replacement for cat)
if command -v bat >/dev/null 2>&1; then
    alias cat="bat --paging=never"
fi

# eza (replacement for ls)
if command -v eza >/dev/null 2>&1; then
    alias ls="eza --group-directories-first --icons=auto"
    alias ll="eza -lh --git --group-directories-first --icons=auto"
    alias la="eza -lah --git --group-directories-first --icons=auto"
    alias tree="eza --tree --group-directories-first --icons=auto"
fi

# lazygit
if command -v lazygit >/dev/null 2>&1; then
    alias lg="lazygit"
fi
