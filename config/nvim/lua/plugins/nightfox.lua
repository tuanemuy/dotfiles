return {
	"edeneast/nightfox.nvim",
	enabled = false,
	lazy = false,
	priority = 1000,
	config = function()
		if vim.opt.background:get() == "light" then
			vim.cmd.colorscheme("dayfox")
		else
			vim.cmd.colorscheme("terafox")
		end
	end,
}
