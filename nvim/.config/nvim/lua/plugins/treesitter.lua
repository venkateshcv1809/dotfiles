return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  lazy = false,
  build = ":TSUpdate",
  opts = {
    auto_install = true,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false
    },
    indent = {
      enable = true,
    },
      ensure_installed = {
        "bash",
        "c",
        "cpp",
        "css",
        "csv",
        "diff",
        "dockerfile",
        "dot",
        "graphql",
        "html",
        "javascript",
        "json",
        "just",
        "lua",
        "markdown",
        "mermaid",
        "python",
        "rust",
        "scss",
        "sql",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      },
  },

  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}