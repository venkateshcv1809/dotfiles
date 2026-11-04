local parsers = {
  "bash",
  "c",
  "cpp",
  "css",
  "csv",
  "diff",
  "dockerfile",
  "dot",
  "go",
  "graphql",
  "html",
  "javascript",
  "json",
  "just",
  "lua",
  "markdown",
  "markdown_inline",
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
  "zig",
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    if vim.fn.has("nvim-0.12") == 0 then
      vim.notify("nvim-treesitter main requires Neovim 0.12+", vim.log.levels.WARN)
      return
    end
    require("nvim-treesitter").install(parsers)

    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        if not pcall(vim.treesitter.start, args.buf) then
          return
        end
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
