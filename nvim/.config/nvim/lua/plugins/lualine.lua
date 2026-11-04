return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "catppuccin",
    },
    opts = {
        options = {
            theme = "catppuccin-mocha",
            globalstatus = true,
            section_separators = { left = "", right = "" },
            component_separators = { left = "", right = "" },
        },
        sections = {
            lualine_c = {
                {
                    "filename",
                    file_status = true,
                    new_file_status = false,
                    path = 1,
                    shorting_target = 40,
                    symbols = {
                        modified = "●",
                        readonly = "🔒",
                        unnamed = "[No Name]",
                        newfile = "[New]",
                    },
                },
            },
        },
        extensions = { "mason" },
    },
}
