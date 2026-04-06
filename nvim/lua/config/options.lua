vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable netrw (oil.nvim handles file browsing)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Indentation
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true

-- Split
opt.splitbelow = true
opt.splitright = true

-- File
opt.undofile = true
opt.clipboard = "unnamedplus"
opt.updatetime = 250
opt.timeoutlen = 300
