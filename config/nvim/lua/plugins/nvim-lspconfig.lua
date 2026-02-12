return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"saghen/blink.cmp",
		"copilotlsp-nvim/copilot-lsp",
	},
	config = function()
		local capabilities = require("blink.cmp").get_lsp_capabilities()

		vim.lsp.config("*", {
			capabilities = capabilities,
		})

		vim.lsp.config("html", {
			init_options = {
				provideFormatter = false,
			},
		})

		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					runtime = { version = "LuaJIT" },
					format = { enable = false },
				},
			},
		})

		vim.lsp.config("yamlls", {
			capabilities = vim.tbl_deep_extend("force", capabilities, {
				textDocument = {
					foldingRange = {
						dynamicRegistration = false,
						lineFoldingOnly = true,
					},
				},
			}),
		})

		vim.lsp.config("vtsls", {
			root_markers = { "package.json" },
			workspace_required = true,
		})

		vim.lsp.config("denols", {
			root_markers = { "deno.json", "deno.jsonc", "deps.ts" },
			workspace_required = true,
		})

		vim.lsp.enable({
			"biome",
			"copilot_ls",
			"denols",
			"html",
			"lua_ls",
			"nil_ls",
			"pylsp",
			"rust_analyzer",
			"vtsls",
			"yamlls",
		})

		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(event)
				local opts = { buffer = event.buf, silent = true }
				vim.keymap.set("n", "<leader>e", function()
					vim.diagnostic.open_float({ focus = false })
				end, opts)
				vim.keymap.set("n", "<leader>w", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, opts)
				vim.keymap.set("n", "<leader>n", vim.lsp.buf.rename, opts)
			end,
		})
	end,
}
