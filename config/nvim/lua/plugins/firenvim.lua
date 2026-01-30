return {
	"glacambre/firenvim",
	enabled = false,
	build = ":call firenvim#install(0)",
	config = function()
		if vim.g.started_by_firenvim == true then
			vim.opt.signcolumn = "no"
			vim.opt.laststatus = 0
			vim.opt.background = "light"
			vim.opt.cursorline = false
			vim.opt.number = false
			vim.opt.fillchars:append({ eob = " " })

			require("lualine").hide()
		end
	end,
}
