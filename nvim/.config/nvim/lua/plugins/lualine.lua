return {
    {
        'nvim-lualine/lualine.nvim',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
        opts = {
            options = {
                theme = require("catppuccin.utils.lualine")('mocha'),
                globalstatus = true,
                section_separators = { left = '', right = '' },
                component_separators = { left = '', right = '' }
            },
            extensions = { 'mason' }
        },
    },
}
