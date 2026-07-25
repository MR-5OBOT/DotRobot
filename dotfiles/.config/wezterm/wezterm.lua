local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- Linux config. Font/cursor/bell mirror ~/.config/kitty/kitty.conf and colors
-- mirror ~/.config/kitty/black.ini, so this looks identical to the kitty setup
-- it replaces. tmux is not used under this terminal: WezTerm speaks the kitty
-- graphics protocol directly, which tmux blocks, so image previews only work
-- when nothing is multiplexing in between.

--------------------------------------------------------------------------- font
config.font = wezterm.font("IosevkaTerm Nerd Font")
config.font_size = 11.5
config.line_height = 1.0
config.cell_width = 0.95 -- kitty: modify_font cell_width 95%

-------------------------------------------------------------------------- colors
-- Base16 Black (metalelf0), same values as kitty/black.ini
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
	-- Pane borders carry the accent, matching tmux's pane-active-border-style
	split = "#BE4277",
	tab_bar = {
		background = "#000000",
		active_tab = { bg_color = "#000000", fg_color = "#c1c1c1", intensity = "Bold" },
		inactive_tab = { bg_color = "#000000", fg_color = "#505050" },
		inactive_tab_hover = { bg_color = "#121212", fg_color = "#c1c1c1" },
		new_tab = { bg_color = "#000000", fg_color = "#505050" },
	},
}

-------------------------------------------------------------------------- window
config.window_background_opacity = 1.0
config.window_decorations = "RESIZE" -- kitty: hide_window_decorations yes
config.window_padding = { left = 5, right = 5, top = 5, bottom = 5 } -- kitty: window_margin_width 5
config.default_cursor_style = "BlinkingBlock" -- kitty: cursor_shape block + cursor_blink true
config.audible_bell = "Disabled" -- kitty: enable_audio_bell no
config.scrollback_lines = 5000
config.inactive_pane_hsb = { saturation = 1.0, brightness = 1.0 } -- no dimming, kitty does not dim

------------------------------------------------------------------------ tab bar
-- Status line stands in for tmux's: centred tabs on top, accent prefix rail.
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.tab_max_width = 24
config.status_update_interval = 1000

------------------------------------------------------------------------ sessions
-- Replaces tmux sessions: the mux server keeps panes alive when the GUI closes,
-- and the GUI reconnects to it on launch. `wezterm cli list` to inspect.
config.unix_domains = { { name = "unix" } }
config.default_gui_startup_args = { "connect", "unix" }

-------------------------------------------------------------------------- keys
-- Leader mirrors tmux's prefix so the muscle memory carries over unchanged.
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	-- send a literal C-Space through (tmux: bind C-Space send-prefix)
	{ key = "Space", mods = "LEADER|CTRL", action = act.SendKey({ key = "Space", mods = "CTRL" }) },

	-- windows/tabs
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "Tab", mods = "LEADER", action = act.ActivateTabRelative(1) },

	-- splits, in the current directory (tmux: -c "#{pane_current_path}")
	{ key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- pane navigation
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },

	-- tmux: bind Space -- no layout presets in wezterm, rotate is the nearest
	{ key = "Space", mods = "LEADER", action = act.RotatePanes("Clockwise") },

	-- tmux: bind r source-file / bind R rename-window / bind d detach
	{ key = "r", mods = "LEADER", action = act.ReloadConfiguration },
	{
		key = "R",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Rename tab",
			action = wezterm.action_callback(function(window, _, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
	{ key = "d", mods = "LEADER", action = act.DetachDomain("CurrentPaneDomain") },

	-- tmux: bind G lazygit in a new window
	{ key = "G", mods = "LEADER", action = act.SpawnCommandInNewTab({ args = { "lazygit" } }) },

	-- tmux: bind-key b set-option status
	{
		key = "b",
		mods = "LEADER",
		action = wezterm.action_callback(function(window)
			local o = window:get_config_overrides() or {}
			o.enable_tab_bar = not (o.enable_tab_bar == nil and true or o.enable_tab_bar)
			window:set_config_overrides(o)
		end),
	},

	-- copy mode, vi keys (tmux: setw -g mode-keys vi)
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },

	-- resize sub-mode (tmux-style: leader+s then hjkl, Escape to leave)
	{ key = "s", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
}

config.key_tables = {
	resize_pane = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 3 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 3 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 3 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 3 }) },
		{ key = "Escape", action = "PopKeyTable" },
	},
}

------------------------------------------------------------------------- status
-- Mirrors tmux's status-left: a solid accent rail + chord label, shown only
-- while the leader is armed.
wezterm.on("update-status", function(window, _)
	if window:leader_is_active() then
		window:set_left_status(wezterm.format({
			{ Foreground = { Color = "#BE4277" } },
			{ Attribute = { Intensity = "Bold" } },
			{ Text = " ▌ C-SPACE " },
		}))
	else
		window:set_left_status("")
	end

	window:set_right_status(wezterm.format({
		{ Foreground = { Color = "#505050" } },
		{ Text = wezterm.strftime(" %H:%M  %d-%b-%y ") },
	}))
end)

return config
