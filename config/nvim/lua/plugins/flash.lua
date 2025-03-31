return {
	"folke/flash.nvim",
	event = "VeryLazy",
	---@type Flash.Config
	opts = {
		jump = {
			autojump = false,
		},
		modes = {
			char = {
				autohide = false,
				jump_labels = true,
				keys = { "f", "F" },
			},
		},
	},
  -- stylua: ignore
  keys = {
    { "<C-f>", mode = { "n", "x", "o" }, function() require("flash").jump() end,       desc = "Flash" },
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
  },
}
