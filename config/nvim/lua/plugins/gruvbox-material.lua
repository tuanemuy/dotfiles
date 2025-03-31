return {
	"sainnhe/gruvbox-material",
	lazy = false,
	priority = 1000,
	config = function()
		vim.g.gruvbox_material_enable_italic = true
		vim.g.gruvbox_material_foreground = "original"
		vim.g.gruvbox_material_background = "medium"
		vim.g.gruvbox_material_better_performance = 1
		vim.g.gruvbox_material_ui_contrast = "high"
		vim.g.gruvbox_material_statusline_style = "original"
		vim.cmd.colorscheme("gruvbox-material")
	end,
}
