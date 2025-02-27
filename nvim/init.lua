vim.opt.background = "dark"
vim.opt.number = true
vim.opt.hlsearch = true
vim.opt.ruler = true
vim.opt.title = true
vim.opt.incsearch = true
vim.opt.wildmenu = true
vim.opt.wildmode = "list:full"
vim.opt.display = "lastline"
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.encoding = "utf-8"
vim.opt.fenc = "utf-8"
vim.opt.mouse = "a"
vim.opt.clipboard:append({ "unnamedplus" })
vim.opt.wrap = false
vim.opt.autoread = true
vim.opt.hidden = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.updatetime = 500
vim.opt.signcolumn = "yes"
vim.opt.list = true
vim.opt.listchars =
	{ tab = "⁚⁚", trail = "-", eol = "↲", extends = "»", precedes = "«", nbsp = "⋅", space = "⋅" }
vim.g.mapleader = " "

-- lazy.nvim
require("config.lazy")

-- Terminal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")

-- Color
vim.opt.termguicolors = true
vim.cmd("syntax enable")
vim.cmd("filetype plugin indent on")

-- Filetype
vim.api.nvim_create_augroup("Filetype", { clear = true })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.tsx",
	command = "set filetype=typescriptreact",
	group = "Filetype",
	desc = "Set filetype to typescriptreact for *.tsx files",
})
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.blade.php",
	command = "set ft=blade",
	group = "Filetype",
})
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.twig",
	command = "set ft=htmldjango",
	group = "Filetype",
})
