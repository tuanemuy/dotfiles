return {
	"stevearc/oil.nvim",
	---@module 'oil'
	---@type oil.SetupOpts
	opts = {},
	-- Optional dependencies
	dependencies = {
		{ "echasnovski/mini.icons", opts = {} },
		"nvim-tree/nvim-web-devicons",
		"folke/snacks.nvim",
	},
	config = function()
		require("oil").setup({
			view_options = {
				winbar = "%{v:lua.require('oil').get_current_dir()}",
				show_hidden = true,
				sort = {
					{ "ctime", "desc" },
				},
			},
			delete_to_trash = true,
			skip_confirm_for_simple_edits = true,
		})
		vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
	end,
	init = function()
		vim.api.nvim_create_autocmd("User", {
			pattern = "OilActionsPost",
			callback = function(event)
				if event.data.actions.type == "move" then
					Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
				end
			end,
		})
	end,
}
