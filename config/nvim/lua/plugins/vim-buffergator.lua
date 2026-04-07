return {
	"jeetsukumaran/vim-buffergator",
	cmd = { "BuffergatorOpen", "BuffergatorToggle" },
	keys = { { "<leader>b", "<CMD>BuffergatorToggle<CR>", desc = "Buffer List" } },
	config = function()
		vim.g.buffergator_viewport_split_policy = "L"
		vim.g.buffergator_split_size = 40
		vim.g.buffergator_sort_regime = "mru"
		vim.g.buffergator_display_regime = "parentdir"
	end,
}
