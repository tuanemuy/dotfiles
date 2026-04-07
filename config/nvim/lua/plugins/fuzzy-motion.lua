return {
	"yuki-yano/fuzzy-motion.vim",
	keys = { { "<C-g>", "<CMD>FuzzyMotion<CR>", desc = "Fuzzy Motion" } },
	dependencies = {
		"vim-denops/denops.vim",
		"lambdalisue/kensaku.vim",
	},
	config = function()
		vim.g.fuzzy_motion_matchers = { "kensaku", "fzf" }
	end,
}
