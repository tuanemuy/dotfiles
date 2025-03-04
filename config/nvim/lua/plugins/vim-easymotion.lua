return {
	"easymotion/vim-easymotion",
	enabled = false,
	config = function()
		vim.g.EasyMotion_do_mapping = 0
		vim.g.EasyMotion_verbose = 0
		vim.keymap.set("", "<Leader>w", "<Plug>(easymotion-bd-w)")
		vim.keymap.set("", "<Leader>l", "<Plug>(easymotion-lineforward)")
		vim.keymap.set("", "<Leader>j", "<Plug>(easymotion-j)")
		vim.keymap.set("", "<Leader>k", "<Plug>(easymotion-k)")
		vim.keymap.set("", "<Leader>h", "<Plug>(easymotion-linebackward)")
	end,
}
