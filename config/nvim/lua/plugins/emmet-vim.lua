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
		vim.api.nvim_create_augroup("Emmet", { clear = true })
		vim.api.nvim_create_autocmd({ "BufNewFile", "BufEnter" }, {
			pattern = { "*.html", "*.css", "*.scss", "*.js", "*.ts", "*.jsx", "*.tsx", "*.php" },
			command = "imap <buffer> <expr> <tab> emmet#expandAbbrIntelligent('<tab>')",
			group = "Emmet",
		})
	end,
}
