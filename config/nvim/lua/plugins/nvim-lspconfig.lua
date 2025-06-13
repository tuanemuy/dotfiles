return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"saghen/blink.cmp",
	},
	config = function()
		vim.lsp.config(
			"*",
			(function()
				local opts = {}
				opts.capabilities = require("blink.cmp").get_lsp_capabilities()
				return opts
			end)()
		)

		vim.lsp.config("html", {
			init_options = {
				provideFormatter = false,
			},
		})

		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					runtime = {
						version = "LuaJIT",
					},
					format = {
						enable = false,
					},
				},
			},
		})

		vim.lsp.config("yamlls", {
			(function()
				local opts = {
					textDocument = {
						foldingRange = {
							dynamicRegistration = false,
							lineFoldingOnly = true,
						},
					},
				}
				opts.capabilities = require("blink.cmp").get_lsp_capabilities()
				return opts
			end)(),
		})

		vim.lsp.config("vtsls", {
			root_markers = {
				"package.json",
			},
			workspace_required = true,
		})

		vim.lsp.config("denols", {
			root_markers = {
				"deno.json",
				"deno.jsonc",
				"deps.ts",
			},
			workspace_required = true,
		})

		vim.lsp.enable({
			"biome",
			"html",
			"lua_ls",
			"nil_ls",
			"pylsp",
			"rust_analyzer",
			"vtsls",
			"denols",
			"yamlls",
		})

		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(_)
				--- vim.keymap.set("n", "<leader>f", "<cmd>lua vim.lsp.buf.format()<CR>", { silent = true })
				vim.keymap.set(
					"n",
					"<leader>e",
					"<cmd>lua vim.diagnostic.open_float(nil, {focus=false})<CR>",
					{ silent = true }
				)
				vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", { silent = true })
			end,
		})
	end,
}
