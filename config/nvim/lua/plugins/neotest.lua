return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-neotest/neotest-jest",
		"marilari88/neotest-vitest",
	},
	keys = {
		{ "<leader>tr", "<cmd>Neotest run <cr>", desc = "run nearest test" },
		{ "<leader>tl", "<cmd>Neotest run last<cr>", desc = "run last test" },
		{ "<leader>tf", "<cmd>Neotest run file<cr>", desc = "run test file" },
		{ "<leader>ts", "<cmd>Neotest summary<cr>", desc = "summary" },
		{ "<leader>tp", "<cmd>Neotest output<cr>", desc = "output" },
	},
	config = function()
		require("neotest").setup({
			adapters = {
				require("neotest-jest")({
					jestConfigFile = function(file)
						if file:find("/packages/") or file:find("/apps/") then
							-- Matches "some/path/" in "some/path/src/"
							local match = file:match("(.*/[^/]+/)src")

							if match then
								return match .. "jest.config.cjs"
							end
						end

						return vim.fn.getcwd() .. "/jest.config.cjs"
					end,
					cwd = function(file)
						if file:find("/packages/") or file:find("/apps/") then
							-- Matches "some/path/" in "some/path/src/"
							local match = file:match("(.*/[^/]+/)src")

							if match then
								return match
							end
						end

						return vim.fn.getcwd()
					end,
					env = { CI = true },
				}),
				require("neotest-vitest")({
					-- Filter directories when searching for test files. Useful in large projects (see Filter directories notes).
					filter_dir = function(name, rel_path, root)
						return name ~= "node_modules"
					end,
				}),
			},
		})
	end,
}
