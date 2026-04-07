return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
	keys = {
		{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff View" },
		{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (current)" },
		{ "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "File History (all)" },
	},
	opts = {
		view = {
			merge_tool = {
				layout = "diff3_mixed",
			},
		},
		file_panel = {
			listing_style = "tree",
			tree_options = {
				flatten_dirs = true,
				folder_statuses = "only_folded",
			},
			win_config = {
				position = "left",
				width = 35,
			},
		},
		hooks = {
			diff_buf_read = function()
				vim.opt_local.wrap = false
				vim.opt_local.list = false
			end,
		},
	},
}
