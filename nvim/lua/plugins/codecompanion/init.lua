return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		{ "nvim-lua/plenary.nvim" },
		{ "nvim-treesitter/nvim-treesitter" },
		{
			"MeanderingProgrammer/render-markdown.nvim",
			ft = { "codecompanion" },
		},
		{
			"j-hui/fidget.nvim",
			config = function()
				require("fidget").setup({
					notification = {
						window = {
							winblend = 0,
						},
					},
				})
			end,
		},
	},
	init = function()
		require("plugins.codecompanion.fidget-spinner"):init()
	end,
	config = function()
		require("codecompanion").setup({
			strategies = {
				chat = { adapter = "copilot" },
				inline = { adapter = "copilot" },
				agent = { adapter = "copilot" },
			},
			opts = {
				language = "Japanese",
			},
			display = {
				action_palette = {
					provider = "telescope",
				},
				chat = {
					window = {
						position = "right",
						width = 0.25,
					},
					slash_commands = {
						["file"] = {
							callback = "strategies.chat.slash_commands.file",
							opts = {
								provider = "telescope",
								contains_code = true,
							},
						},
					},
				},
			},
			adapters = {
				copilot = function()
					return require("codecompanion.adapters").extend("copilot", {
						schema = {
							model = {
								default = "claude-3.5-sonnet",
							},
						},
					})
				end,
			},
		})
		vim.keymap.set({ "n", "v" }, "<C-a>", "<cmd>CodeCompanionActions<cr>", { silent = true })
		vim.keymap.set({ "n", "v" }, "<Leader>a", "<cmd>CodeCompanionChat Toggle<cr>", { silent = true })
		vim.keymap.set("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { silent = true })
		-- Expand 'cc' into 'CodeCompanion' in the command line
		vim.cmd([[cab cc CodeCompanion]])
	end,
}
