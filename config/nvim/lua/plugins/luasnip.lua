return {
	"L3MON4D3/LuaSnip",
	version = "v2.*",
	dependencies = {
		{ "rafamadriz/friendly-snippets" },
	},
	build = "make install_jsregexp",
	config = function()
		require("luasnip/loaders/from_vscode").load()
	end,
}
