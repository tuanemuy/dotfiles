return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	lazy = false,
	config = function()
		-- ハイライトは Neovim ビルトインの ftplugin に任せる
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

		-- tree-sitter パーサーがある場合のみ indent を有効化
		vim.api.nvim_create_autocmd("FileType", {
			callback = function()
				local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
				if lang and pcall(vim.treesitter.language.inspect, lang) and vim.bo.indentexpr == "" then
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
