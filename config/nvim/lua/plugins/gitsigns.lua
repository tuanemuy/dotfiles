-- nvim 0.13 nightly: nvim_buf_call/nvim_win_call がコルーチン内で戻り値を落とすバグの回避
for _, name in ipairs({ "nvim_buf_call", "nvim_win_call" }) do
	local orig = vim.api[name]
	vim.api[name] = function(h, fn)
		local r
		orig(h, function()
			r = fn()
		end)
		return r
	end
end

return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	keys = {
		{
			"<leader>gb",
			function()
				require("gitsigns").blame_line()
			end,
			desc = "Git Blame Line",
		},
	},
	opts = {},
}
