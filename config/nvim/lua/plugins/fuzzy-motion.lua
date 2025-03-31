return {
	"yuki-yano/fuzzy-motion.vim",
	dependencies = {
		"vim-denops/denops.vim",
		"lambdalisue/kensaku.vim",
	},
	config = function()
		vim.keymap.set("n", "<C-g>", "<CMD>FuzzyMotion<CR>")
		vim.g.fuzzy_motion_matchers = { 'kensaku', 'fzf'}
	end,
}
