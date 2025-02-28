return {
	"neovim/nvim-lspconfig",
	dependencies = {
		{ "saghen/blink.cmp" },
		{ "yioneko/nvim-vtsls" },
	},
	opts = {
		servers = {
			biome = {},
			html = {
				init_options = {
					provideFormatter = false,
				},
			},
			lua_ls = {
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
			},
			nil_ls = {},
			pylsp = {},
			rust_analyzer = {},
			vtsls = {
				on_attach = function(client)
					client.server_capabilities.documentFormattingProvider = false
				end,
			},
			yamlls = {
				capabilities = {
					textDocument = {
						foldingRange = {
							dynamicRegistration = false,
							lineFoldingOnly = true,
						},
					},
				},
			},
		},
	},
	config = function(_, opts)
		local lspconfig = require("lspconfig")
		require("lspconfig.configs").vtsls = require("vtsls").lspconfig
		for server, config in pairs(opts.servers) do
			config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
			lspconfig[server].setup(config)
		end

		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(_)
				--- vim.keymap.set("n", "<leader>f", "<cmd>lua vim.lsp.buf.format()<CR>", { silent = true })
				vim.keymap.set(
					"n",
					"<leader>e",
					"<cmd>lua vim.diagnostic.open_float(nil, {focus=false})<CR>",
					{ silent = true }
				)
				vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", { silent = true })
				vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { silent = true })
				vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { silent = true })
				vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", { silent = true })
			end,
		})
	end,
}
