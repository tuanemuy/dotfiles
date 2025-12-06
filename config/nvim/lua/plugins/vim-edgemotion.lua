return {
	"haya14busa/vim-edgemotion",
	config = function()
		vim.keymap.set("n", "<C-j>", "<Plug>(edgemotion-j)")
		vim.keymap.set("n", "<C-k>", "<Plug>(edgemotion-k)")
	end,
}
