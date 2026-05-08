return {
	"NotAShelf/direnv.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		require("direnv").setup({
			autoload_direnv = true,
			statusline = { enabled = false },
			notifications = {
				level = vim.log.levels.WARN,
				silent_autoload = true,
			},
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = "DirenvLoaded",
			callback = function()
				for _, client in ipairs(vim.lsp.get_clients()) do
					client:stop()
				end
				vim.defer_fn(function()
					vim.cmd("edit")
				end, 100)
			end,
		})
	end,
}
