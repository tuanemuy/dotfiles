return {
	"copilotlsp-nvim/copilot-lsp",
	enabled = false,
	init = function()
		vim.g.copilot_nes_debounce = 500
	end,
	config = function()
		require("copilot-lsp").setup({
			nes = {
				move_count_threshold = 3, -- Clear after 3 cursor movements
			},
		})
	end,
}
