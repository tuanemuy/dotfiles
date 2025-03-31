return {
	"bkad/CamelCaseMotion",
	config = function()
		vim.keymap.set("", "w", "<Plug>CamelCaseMotion_w", { silent = true })
	end,
}
