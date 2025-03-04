return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	dependencies = { "lambdalisue/kensaku.vim" },
	---@type snacks.Config
	opts = {
		bigfile = { enabled = true },
		bufdelete = { enabled = true },
		explorer = { enabled = true },
		indent = { enabled = true },
		input = { enabled = true },
		lazygit = { enabled = true },
		picker = {
			sources = {
				explorer = {
					auto_close = true,
				},
			},
		},
		scope = { enabled = true },
		scratch = { enabled = true },
		scroll = { enabled = true },
		styles = {},
	},
  -- stylua: ignore
  keys = {
    -- Top Pickers & Explorer
    { "<leader>fi", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep" },
		{
			"<leader>fk",
			function()
				require("snacks.picker.config.sources").grep_kensaku = require("plugins/snacks/sources/grep_kensaku")
				Snacks.picker.grep_kensaku()
			end,
			desc = "Grep with kensaku.vim",
		},
    { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader>fn", function() Snacks.picker.notifications() end, desc = "Notification History" },
    { "<leader>,", function() Snacks.explorer() end, desc = "File Explorer" },
    -- find
		{ "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
    { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent" },
    -- git
    { "<leader>gb", function() Snacks.picker.git_branches() end, desc = "Git Branches" },
    -- LSP
    { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
    { "gD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration" },
    { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
    { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
    { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
    -- Other
    { "<leader>z",  function() Snacks.zen() end, desc = "Toggle Zen Mode" },
    { "<leader>Z",  function() Snacks.zen.zoom() end, desc = "Toggle Zoom" },
    { "<leader>.",  function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
    { "<leader>S",  function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
    { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
    { "<leader>bx", function() Snacks.bufdelete.all() end, desc = "Delete All Buffers" },
    { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
  },
	init = function()
		vim.api.nvim_create_autocmd("User", {
			pattern = "VeryLazy",
			callback = function()
				-- Setup some globals for debugging (lazy-loaded)
				_G.dd = function(...)
					Snacks.debug.inspect(...)
				end
				_G.bt = function()
					Snacks.debug.backtrace()
				end
				vim.print = _G.dd -- Override print to use snacks for `:=` command
			end,
		})
	end,
}
