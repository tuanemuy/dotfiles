return {
	"folke/noice.nvim",
	event = "VeryLazy",
	opts = {
		messages = {
			view = "mini",
		},
		views = {
			notify = {
				replace = true,
			},
		},
	},
	dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},
}
