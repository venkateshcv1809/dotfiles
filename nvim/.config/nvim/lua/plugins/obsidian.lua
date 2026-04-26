return {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
        legacy_commands = false,
        attachments = {
            folder = "./attachments",
        },
        daily_notes = {
            folder = "Sprint/Daily",
            date_format = "%Y-%m-%d",
            template = "Daily",
        },
        notes_subdir = "temp",
        templates = {
            folder = "Templates",
        },
        workspaces = {
            {
                name = "personal",
                path = "~/Documents/Notes",
            },
        },
    },
}