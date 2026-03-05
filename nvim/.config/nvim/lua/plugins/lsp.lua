return {
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {
        "bashls",
        "clangd",
        "cssls",
        "dockerls",
        "dotls",
        "eslint",
        "graphql",
        "html",
        "jsonls",
        "lua_ls",
        "marksman",
        "pyright",
        "rust_analyzer",
        "sqlls",
        "taplo",
        "ts_ls",
        "yamlls"
    },
      automatic_enable = true,
    },
  }
}
