return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		{ "nvim-tree/nvim-web-devicons" },
	},
	config = function()
		local colors = {
			fg = "#928374",
			bg = "",
			accent = "#d79921",
		}
		require("lualine").setup({
			options = {
				icons_enabled = true,
				theme = {
					normal = { c = { fg = colors.fg, bg = colors.bg } },
					inactive = { c = { fg = colors.fg, bg = colors.bg } },
				},
				component_separators = { left = "・", right = "・" },
				section_separators = {},
				disabled_filetypes = {
					statusline = {},
					winbar = { "fern", "snacks_picker_list" },
				},
				ignore_focus = {},
				always_divide_middle = false,
				globalstatus = true,
				refresh = {
					statusline = 100,
					tabline = 100,
					winbar = 100,
				},
			},
			sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = {
					{
						"mode",
						separator = { left = "", right = "" },
						padding = { left = 1, right = 2 },
						fmt = function(mode)
							local icons = {
								["NORMAL"] = "",
								["INSERT"] = "",
								["O-PENDING"] = "󰺕",
								["VISUAL"] = "󰫙",
								["V-LINE"] = "󰒆",
								["V-BLOCK"] = "󰾂",
								["REPLACE"] = "",
								["V-REPLACE"] = "󰫙 *",
								["COMMAND"] = "󰞷",
								["TERMINAL"] = "",
							}

							return icons[mode] or mode
						end,
					},
					{ "branch", icon = "  " },
					"diff",
					"diagnostics",
					{ "filename", path = 4 },
					{
						function()
							local count = 0
							local buf_ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
							local clients = vim.lsp.get_clients()
							for _, client in ipairs(clients) do
								count = count + 1
							end
							return count
						end,
						icon = "",
						color = { fg = colors.accent },
					},
				},
				lualine_x = {
					{ "encoding" },
					{ "filetype" },
					{ "progress" },
					{ "location", padding = { left = 0, right = 0 } },
				},
				lualine_y = {},
				lualine_z = {},
			},
			inactive_sections = {},
			tabline = {},
			winbar = {
				lualine_x = { { "filename", path = 1 } },
			},
			inactive_winbar = {
				lualine_x = { { "filename", path = 1 } },
			},
			extensions = {},
		})
		vim.api.nvim_set_hl(0, "WinBar", { bg = "none", bold = false })
	end,
}
