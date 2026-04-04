return {
	"easymotion/vim-easymotion",
	keys = {
		{ "<Leader>l", "<Plug>(easymotion-lineforward)", desc = "EasyMotion Forward" },
		{ "<Leader>j", "<Plug>(easymotion-j)", desc = "EasyMotion Down" },
		{ "<Leader>k", "<Plug>(easymotion-k)", desc = "EasyMotion Up" },
		{ "<Leader>h", "<Plug>(easymotion-linebackward)", desc = "EasyMotion Backward" },
	},
	init = function()
		vim.g.EasyMotion_do_mapping = 0
		vim.g.EasyMotion_verbose = 0
	end,
}
