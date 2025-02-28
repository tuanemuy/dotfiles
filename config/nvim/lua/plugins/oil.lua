return {
	"stevearc/oil.nvim",
	---@module 'oil'
	---@type oil.SetupOpts
	opts = {},
	-- Optional dependencies
	dependencies = { { "echasnovski/mini.icons", opts = {} }, "nvim-tree/nvim-web-devicons" },
	config = function()
		require("oil").setup({
			view_options = {
				winbar = "%{v:lua.require('oil').get_current_dir()}",
				show_hidden = true,
			},
		})
		vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
	end,
}
