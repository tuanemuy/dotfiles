return {
	"akinsho/toggleterm.nvim",
	version = "*",
	keys = { { "<C-t>", desc = "Toggle Terminal", mode = { "n", "t" } } },
	config = function()
		require("toggleterm").setup({
			open_mapping = [[<c-t>]],
			direction = "float",
		})
	end,
}
