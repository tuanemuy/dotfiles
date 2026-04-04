return {
	"nvim-telescope/telescope.nvim",
	enabled = false,
	tag = "0.1.8",
	keys = {
		{
			"<leader>ff",
			function()
				require("telescope.builtin").find_files()
			end,
			desc = "Telescope find files",
		},
		{ "<leader>fg", "<CMD>Telescope kensaku<CR>", desc = "Telescope kensaku" },
		{
			"<leader>fh",
			function()
				require("telescope.builtin").help_tags()
			end,
			desc = "Telescope help tags",
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"Allianaab2m/telescope-kensaku.nvim",
	},
	config = function()
		require("telescope").load_extension("kensaku")
	end,
}
