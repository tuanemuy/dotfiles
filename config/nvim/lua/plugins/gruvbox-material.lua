return {
	"sainnhe/gruvbox-material",
	lazy = false,
	priority = 1000,
	config = function()
		-- Optionally configure and load the colorscheme
		-- directly inside the plugin declaration.
		vim.g.gruvbox_material_enable_italic = true
		vim.g.gruvbox_material_background = "medium"
		vim.g.gruvbox_material_better_performance = 1
		vim.cmd.colorscheme("gruvbox-material")
		vim.cmd("highlight Normal ctermbg=NONE guibg=NONE")
		vim.cmd("highlight NonText ctermbg=NONE guibg=NONE")
		vim.cmd("highlight LineNr ctermbg=NONE guibg=NONE")
		vim.cmd("highlight Folded ctermbg=NONE guibg=NONE")
		vim.cmd("highlight EndOfBuffer ctermbg=NONE guibg=NONE")
	end,
}
