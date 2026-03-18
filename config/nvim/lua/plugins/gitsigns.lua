return {
	"lewis6991/gitsigns.nvim",
	config = function()
		vim.keymap.set("n", "<leader>gh", "<Cmd>Gitsigns blame_line<Cr>", opts)
	end,
}
