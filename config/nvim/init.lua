vim.opt.background = os.getenv("CURRENT_THEME") == "light" and "light" or "dark"
vim.opt.number = true
-- vim.opt.relativenumber = true
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
	{ tab = "▸\\", trail = "-", eol = "↲", extends = "»", precedes = "«", nbsp = "⋅", space = "⋅" }
vim.opt.exrc = true
vim.g.mapleader = " "

-- lazy.nvim
require("config.lazy")

-- Terminal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")

vim.keymap.set("n", "J", "10gj")
vim.keymap.set("n", "K", "10gk")

vim.opt.termguicolors = true
vim.cmd("syntax enable")
vim.cmd("filetype plugin indent on")

-- Filetype
vim.api.nvim_create_augroup("Filetype", { clear = true })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.mdc",
	command = "set ft=markdown",
	group = "Filetype",
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
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.csvd",
	command = "set ft=csv",
	group = "Filetype",
})
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*.tsvd",
	command = "set ft=tsv",
	group = "Filetype",
})

vim.api.nvim_create_autocmd({ "WinEnter", "FocusGained", "BufEnter" }, {
	pattern = "*",
	command = "checktime",
})

-- ステージングされた変更のdiffを取得し、コメントアウトしてコミットメッセージに挿入する
local function append_diff()
	-- Gitリポジトリのルートディレクトリを取得
	local git_root = vim.fn.system("git rev-parse --show-toplevel")
	-- 末尾の改行を削除
	git_root = string.gsub(git_root, "\n$", "")

	if git_root == "" then
		return
	end

	-- ステージングされた変更のdiffを取得 (git -C <path> diff --cached)
	local diff_command = "git -C " .. vim.fn.shellescape(git_root) .. " diff --cached"
	local diff = vim.fn.system(diff_command)

	-- diffの各行にコメント文字 '#' を追加
	local commented_diff = {}
	for _, line in ipairs(vim.split(diff, "\n", {})) do
		table.insert(commented_diff, "# " .. line)
	end

	-- コミットメッセージの末尾にdiffを追記
	vim.api.nvim_buf_set_lines(0, vim.fn.line("$"), vim.fn.line("$"), false, commented_diff)
end

vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = "COMMIT_EDITMSG",
	callback = append_diff,
	desc = "Append staged diff to commit message",
})
