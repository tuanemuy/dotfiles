local function open_pr_diff()
	local result = vim.system({ "gh", "pr", "view", "--json", "baseRefName", "--jq", ".baseRefName" }, { text = true }):wait()

	if result.code ~= 0 then
		vim.notify("Could not resolve PR base branch for current branch", vim.log.levels.ERROR)
		return
	end

	local base = vim.trim(result.stdout or "")
	if base == "" then
		vim.notify("Could not resolve PR base branch for current branch", vim.log.levels.ERROR)
		return
	end

	vim.cmd("DiffviewOpen origin/" .. base .. "...HEAD")
end

return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
	keys = {
		{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff View" },
		{ "<leader>gp", open_pr_diff, desc = "Pull Request Diff" },
		{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (current)" },
		{ "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "File History (all)" },
	},
	opts = {
		view = {
			merge_tool = {
				layout = "diff3_mixed",
			},
		},
		file_panel = {
			listing_style = "tree",
			tree_options = {
				flatten_dirs = true,
				folder_statuses = "only_folded",
			},
			win_config = {
				position = "left",
				width = 30,
			},
		},
		hooks = {
			diff_buf_read = function()
				vim.opt_local.wrap = false
				vim.opt_local.list = false
			end,
		},
	},
}
