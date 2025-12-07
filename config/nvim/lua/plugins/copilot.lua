return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	config = function()
		require("copilot").setup({
			suggestion = {
				auto_trigger = true,
				keymap = {
					accept = "<C-j>",
				},
			},
			filetypes = {
				markdown = true,
				csv = false,
				tsv = false,
				php = true,
				gitcommit = true,
			},
		})
	end,
}
