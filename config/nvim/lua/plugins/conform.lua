return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({ async = true })
			end,
			mode = "",
		},
	},
	config = function()
		require("conform").setup({
			default_format_opts = {
				lsp_format = "fallback",
			},
			formatters = {
				markdownlint_cli2 = {
					command = "markdownlint-cli2",
					stdin = false,
					args = { "--fix", "$FILENAME" },
					exit_codes = { 0, 1 },
					cwd = require("conform.util").root_file({
						".markdownlint.json",
						".markdownlint-cli2.json",
						".markdownlint.jsonc",
						".markdownlint-cli2.jsonc",
					}),
				},
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
				markdown = { "markdownlint_cli2" },
				rust = { "rustfmt", lsp_format = "fallback" },
				python = { "ruff_format" },
				nix = { "nixfmt" },
			},
		})
	end,
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
			markdown = { "markdownlint_cli2" },
			rust = { "rustfmt", lsp_format = "fallback" },
			python = { "ruff_format" },
			nix = { "nixfmt" },
		},
	},
}
