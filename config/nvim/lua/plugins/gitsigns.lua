return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	keys = {
		{
			"<leader>gb",
			function()
				require("gitsigns").blame_line()
			end,
			desc = "Git Blame Line",
		},
	},
	opts = {},
}
