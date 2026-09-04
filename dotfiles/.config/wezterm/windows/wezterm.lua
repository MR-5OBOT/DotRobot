local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Font + cursor + bell mirror ~/.config/kitty/kitty.conf from DotRobot (Linux dotfiles)
config.font = wezterm.font("IosevkaTerm Nerd Font")
config.font_size = 11.5
config.line_height = 1.0

-- Colors mirror ~/.config/kitty/black.ini (Base16 Black, by metalelf0) - the theme
-- actually `include`d by kitty.conf. fsociety.ini also exists in DotRobot as an
-- alternate scheme, ask if you want that ported instead.
config.colors = {
	foreground = "#c1c1c1",
	background = "#000000",
	cursor_bg = "#c1c1c1",
	cursor_border = "#c1c1c1",
	cursor_fg = "#000000",
	selection_fg = "#000000",
	selection_bg = "#c1c1c1",
	ansi = { "#000000", "#5f8787", "#9b8d7f", "#8c7f70", "#888888", "#999999", "#aaaaaa", "#c1c1c1" },
	brights = { "#333333", "#5f8787", "#9b8d7f", "#8c7f70", "#888888", "#999999", "#aaaaaa", "#c1c1c1" },
	tab_bar = {
		background = "#121212",
		active_tab = { bg_color = "#000000", fg_color = "#c1c1c1" },
		inactive_tab = { bg_color = "#121212", fg_color = "#999999" },
		inactive_tab_hover = { bg_color = "#222222", fg_color = "#c1c1c1" },
		new_tab = { bg_color = "#121212", fg_color = "#999999" },
	},
}
config.window_background_opacity = 1.0 -- kitty.conf has no explicit opacity set - solid black

config.window_decorations = "RESIZE" -- matches kitty's hide_window_decorations yes
config.window_padding = { left = 5, right = 5, top = 5, bottom = 5 } -- kitty window_margin_width 5
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

config.default_prog = { "pwsh.exe", "-NoLogo" }
config.wsl_domains = {} -- skip auto-discovering WSL distros at startup - was adding real latency
config.default_cursor_style = "BlinkingBlock" -- kitty cursor_shape block + cursor_blink true
config.audible_bell = "Disabled" -- kitty enable_audio_bell no
config.scrollback_lines = 5000

-- Leader scheme mirrors DotRobot's tmux.conf: prefix = Ctrl+Space, same prefix+key bindings
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	{ key = "c", mods = "LEADER", action = wezterm.action.SpawnTab("CurrentPaneDomain") }, -- tmux default: prefix+c = new window
	{ key = "Tab", mods = "LEADER", action = wezterm.action.ActivateTabRelative(1) }, -- matches prefix+Tab next-window
	{ key = "w", mods = "LEADER", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	{ key = "|", mods = "LEADER|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) }, -- matches prefix+| (side-by-side)
	{ key = "-", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) }, -- matches prefix+- (stacked)
	{ key = "h", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "l", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Right") },
	{ key = "k", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "j", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Down") },
	{ key = "r", mods = "LEADER", action = wezterm.action.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
}

config.key_tables = {
	resize_pane = {
		{ key = "h", action = wezterm.action.AdjustPaneSize({ "Left", 3 }) },
		{ key = "l", action = wezterm.action.AdjustPaneSize({ "Right", 3 }) },
		{ key = "k", action = wezterm.action.AdjustPaneSize({ "Up", 3 }) },
		{ key = "j", action = wezterm.action.AdjustPaneSize({ "Down", 3 }) },
		{ key = "Escape", action = "PopKeyTable" },
	},
}

return config
