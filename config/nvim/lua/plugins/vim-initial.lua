return {
	"lambdalisue/vim-initial",
	enabled = false,
	dependencies = { "vim-denops/denops.vim" },
	config = function()
		vim.keymap.set("n", "t", "<Cmd>Initial<CR>")
	end,
}
