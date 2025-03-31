return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"saghen/blink.cmp",
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
					if not require("lspconfig").util.root_pattern("package.json")(vim.fn.getcwd()) then
						client.stop(true)
					end
				end,
			},
			denols = {
				on_attach = function(client)
					if require("lspconfig").util.root_pattern("package.json")(vim.fn.getcwd()) then
						client.stop(true)
					end
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
				vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", { silent = true })
			end,
		})
	end,
}
