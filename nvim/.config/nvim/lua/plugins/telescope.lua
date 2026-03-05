return {
    'nvim-telescope/telescope.nvim', version = '*',
    dependencies = {
        'nvim-lua/plenary.nvim',
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        local telescope = require('telescope')

        telescope.setup {
            defaults = {
                mappings = {
                    i = {
                        ['<C-u>'] = false,
                    },
                },
            },
            extensions = {
                fzf = {
                    fuzzy = true,
                    override_generic_sorter = true,
                    override_file_sorter = true,
                    case_mode = "smart_case",
                }
            }
        }

        telescope.load_extension('fzf')

        local builtin = require('telescope.builtin')
        local keymap = vim.keymap
        keymap.set('n', '<leader>ff', builtin.find_files, { desc = "Find Files" })
        keymap.set('n', '<leader>fg', builtin.live_grep, { desc = "Live Grep" })
        keymap.set('n', '<leader>fb', builtin.buffers, { desc = "Buffers" })
        keymap.set('n', '<leader>fh', builtin.help_tags, { desc = "Help Tags" })
    end
}