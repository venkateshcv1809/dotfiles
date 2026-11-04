return {
  "rmagatti/auto-session",
  lazy = false,

  ---@module "auto-session"
  ---@type AutoSession.Config
  opts = {
    -- tmux-resurrect / continuum already restore nvim; avoid a second restore.
    auto_restore = vim.env.TMUX == nil,
    suppressed_dirs = { "~/", "~/Downloads", "/" },
  },
}
