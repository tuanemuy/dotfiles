return {
	"lambdalisue/fern.vim",
	dependencies = {
		{ "lambdalisue/nerdfont.vim" },
		{
			"lambdalisue/fern-renderer-nerdfont.vim",
			config = function()
				vim.g["fern#renderer"] = "nerdfont"
			end,
		},
		{ "lambdalisue/glyph-palette.vim" },
	},
	config = function()
		vim.keymap.set("n", "<leader>fe", ":Fern . -drawer -toggle -reveal=%<CR>")
		vim.g["fern#drawer_width"] = 27
		vim.g["fern#default_hidden"] = 1
		vim.g["fern#keepjump_on_edit"] = 1
		vim.g["fern#window_selector_use_popup"] = 1

		local function init_fern()
			-- Use 'select' instead of 'edit' for default 'open' action
			vim.keymap.set("n", "<Plug>(fern-action-open)", "<Plug>(fern-action-open:select)", { buffer = true })
			vim.keymap.set("n", "<CR>", "<Plug>(fern-action-open-or-expand)", { buffer = true })
			vim.keymap.set("n", "l", "<Plug>(fern-action-open-or-enter)", { buffer = true })
			vim.keymap.set("n", "i", "<Plug>(fern-action-open:split)", { buffer = true })
			vim.keymap.set("n", "s", "<Plug>(fern-action-open:vsplit)", { buffer = true })
		end

		-- Set up autocommands for fern
		vim.api.nvim_create_augroup("fern_custom", { clear = true })
		vim.api.nvim_create_autocmd("FileType", {
			group = "fern_custom",
			pattern = "fern",
			callback = init_fern,
		})

		-- Set up autocommands for glyph palette
		vim.api.nvim_create_augroup("my_glyph_palette", { clear = true })
		vim.api.nvim_create_autocmd("FileType", {
			group = "my_glyph_palette",
			pattern = "fern",
			callback = function()
				vim.fn["glyph_palette#apply"]()
			end,
		})
	end,
}
