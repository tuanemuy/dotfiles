return {
	"shellRaining/hlchunk.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	config = function()
		require("hlchunk").setup({
			chunk = {
				enable = true,
				style = {
					{ fg = "#7daea3" },
					{ fg = "#ea6962" },
				},
			},
			indent = {
				enable = true,
			},
			line_num = {
				enable = true,
				style = "#7daea3",
			},
			blank = {
				enable = false,
			},
		})
	end,
}
