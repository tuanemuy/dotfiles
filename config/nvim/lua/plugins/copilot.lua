return {
	"zbirenbaum/copilot.lua",
	dependencies = {
		"copilotlsp-nvim/copilot-lsp",
	},
	cmd = "Copilot",
	event = "InsertEnter",
	config = function()
		require("copilot").setup({
			panel = {
				enabled = false,
			},
			suggestion = {
				auto_trigger = true,
				keymap = {
					accept = "<C-j>",
				},
			},
			nes = {
				enabled = false,
				auto_trigger = false,
				keymap = {
					accept_and_goto = "<C-k>",
				},
			},
			filetypes = {
				markdown = true,
				yaml = true,
				gitcommit = true,
			},
		})
	end,
}
