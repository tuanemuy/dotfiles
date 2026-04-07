return {
	"bkad/CamelCaseMotion",
	event = "VeryLazy",
	config = function()
		vim.keymap.set("", "w", "<Plug>CamelCaseMotion_w", { silent = true })
	end,
}
