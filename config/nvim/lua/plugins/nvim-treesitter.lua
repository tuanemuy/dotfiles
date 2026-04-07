return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	lazy = false,
	config = function()
		require("nvim-treesitter").setup({
			ensure_installed = {
				"bash",
				"comment",
				"css",
				"csv",
				"diff",
				"gitcommit",
				"html",
				"javascript",
				"json",
				"lua",
				"markdown",
				"markdown_inline",
				"mermaid",
				"nginx",
				"nix",
				"php",
				"python",
				"rust",
				"sql",
				"terraform",
				"toml",
				"tsv",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
				"yaml",
			},
		})

		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				pcall(vim.treesitter.start)
				local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
				if lang and vim.bo[args.buf].indentexpr == "" and vim.treesitter.query.get(lang, "indents") then
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
