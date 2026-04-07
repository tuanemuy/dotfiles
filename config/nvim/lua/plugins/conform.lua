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
			format_on_save = true,
			formatters = {
				markdownlint_cli2 = {
					command = "markdownlint-cli2",
					stdin = false,
					args = {
						"--config",
						os.getenv("HOME") .. "/.config/.markdownlint-cli2.jsonc",
						"--fix",
						"$FILENAME",
					},
					exit_codes = { 0, 1 },
				},
			},
			formatters_by_ft = {
				lua = { "stylua" },
				bash = { "shfmt" },
				typescript = { "eslint_d" },
				javascript = { "eslint_d" },
				typescriptreact = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				json = { "prettierd" },
				jsonc = { "prettierd" },
				yaml = { "prettierd" },
				html = { "prettierd" },
				css = { "prettierd" },
				scss = { "prettierd" },
				markdown = { "markdownlint_cli2" },
				rust = { "rustfmt", lsp_format = "fallback" },
				python = { "ruff_format" },
				nix = { "nixfmt" },
				sql = { "sleek" },
				php = { "intelephense" },
			},
		})
	end,
}
