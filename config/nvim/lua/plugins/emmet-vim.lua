return {
	"mattn/emmet-vim",
	dependencies = { "mattn/webapi-vim" },
	ft = { "html", "css", "scss", "javascript", "typescript", "javascriptreact", "typescriptreact", "php" },
	init = function()
		vim.g.user_emmet_leader_key = "<C-z>"
	end,
	config = function()
		vim.g.user_emmet_settings = {
			variables = {
				lang = "ja",
			},
			indentation = "  ",
		}
		vim.g.user_emmet_settings = vim.fn["webapi#json#decode"](
			table.concat(vim.fn.readfile(vim.fn.expand("~/.config/nvim/snippets/emmet.json")), "\n")
		)
		vim.cmd([[imap <expr> <tab> emmet#expandAbbrIntelligent("\<tab>")]])
	end,
}
