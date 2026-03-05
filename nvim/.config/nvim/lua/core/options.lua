local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true
opt.scrolloff = 999

-- Tabs & Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true

-- Appearance
opt.termguicolors = true
opt.cursorline = true

-- Behavior
opt.mouse = 'a'
opt.clipboard = 'unnamedplus' -- Sync with system clipboard