local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Color
config.color_scheme = "Gruvbox light, medium (base16)"

-- Window
config.window_decorations = "RESIZE"
config.window_background_opacity = 1
local padding = { x = 16, y = 16 }
config.window_padding = {
	left = padding.x,
	right = padding.x,
	top = padding.y,
	bottom = 0,
}

-- Tab
config.enable_tab_bar = false

-- Text
config.font = wezterm.font("HackGen Console NF")
config.font_size = 12.5
config.line_height = 1.2

-- Input
config.use_ime = true
config.macos_forward_to_ime_modifier_mask = "SHIFT|CTRL"

-- Keybindings

return config
