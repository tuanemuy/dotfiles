return {
	"pwntester/octo.nvim",
	commit = "7967322",
	cmd = "Octo",
	opts = {
		picker = "snacks",
		-- bare Octo command opens picker of commands
		enable_builtin = true,
	},
	keys = {
		{
			"<leader>oi",
			"<CMD>Octo issue list<CR>",
			desc = "List GitHub Issues",
		},
		{
			"<leader>op",
			"<CMD>Octo pr list<CR>",
			desc = "List GitHub PullRequests",
		},
		{
			"<leader>od",
			"<CMD>Octo discussion list<CR>",
			desc = "List GitHub Discussions",
		},
		{
			"<leader>on",
			"<CMD>Octo notification list<CR>",
			desc = "List GitHub Notifications",
		},
		{
			"<leader>os",
			function()
				require("octo.utils").create_base_search_command({ include_current_repo = true })
			end,
			desc = "Search GitHub",
		},
		{
			"<leader>odf",
			function()
				local buffer = require("octo.utils").get_current_buffer()
				if not buffer or not buffer:isPullRequest() then
					vim.notify("Not in an Octo PR buffer", vim.log.levels.WARN)
					return
				end
				local output = vim.fn.system({
					"gh", "pr", "view", tostring(buffer.number),
					"--repo", buffer.repo,
					"--json", "baseRefName,headRefName",
				})
				local ok, json = pcall(vim.fn.json_decode, output)
				if not ok or not json then
					vim.notify("Failed to get PR info", vim.log.levels.ERROR)
					return
				end
				vim.cmd("DiffviewOpen origin/" .. json.baseRefName .. "...origin/" .. json.headRefName)
			end,
			desc = "Open PR diff in Diffview",
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"folke/snacks.nvim",
		"nvim-tree/nvim-web-devicons",
		"sindrets/diffview.nvim",
	},
}
