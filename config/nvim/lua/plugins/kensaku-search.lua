return {
	"lambdalisue/kensaku-search.vim",
	dependencies = { "lambdalisue/kensaku.vim" },
	config = function()
		vim.keymap.set("c", "<CR>", "<Plug>(kensaku-search-replace)<CR>")
	end,
}
