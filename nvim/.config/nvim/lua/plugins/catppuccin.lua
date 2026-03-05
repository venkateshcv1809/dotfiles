return {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    priority = 1000,
    opts = {
        flavour = "mocha",
        auto_integrations = true,
        integrations = {
            blink_cmp = { style = 'bordered' },
            gitsigns = true,
            mason = true,
            lsp_trouble = true,
            lualine = true,
            telescope = { enabled = true },
        }
    },
    config = function (_, opts)
        require("catppuccin").setup(opts)
        vim.cmd.colorscheme "catppuccin"
    end
}
