return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({ async = true })
			end,
			mode = "",
		},
	},
	opts = {
		default_format_opts = {
			lsp_format = "fallback",
		},
		formatters_by_ft = {
			lua = { "stylua" },
			bash = { "shfmt" },
			typescript = { "biome" },
			javascript = { "biome" },
			typescriptreact = { "biome" },
			javascriptreact = { "biome" },
			json = { "biome" },
			jsonc = { "biome" },
			yaml = { "prettierd" },
			html = { "prettierd" },
			css = { "biome" },
			scss = { "biome" },
			markdown = { "markdownlint-cli2" },
			rust = { "rustfmt", lsp_format = "fallback" },
			python = { "ruff_format" },
			nix = { "nixfmt" },
		},
	},
}
