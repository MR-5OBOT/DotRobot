hl.config({
	general = {
		allow_tearing = true,
		hover_icon_on_border = true,
		-- snap = {
		-- 	enabled = true,
		-- 	respect_gaps = true,
		-- },
	},
	input = {
		natural_scroll = false,
		sensitivity = -0.05,
	},
	misc = {
		-- let apps raise themselves on activation (e.g. clicking a notification
		-- switches to WhatsApp/Telegram); Hyprland defaults this off
		focus_on_activate = false,
		-- quickshell paints the wallpaper, so a qs restart leaves the background
		-- bare for a moment. Show a dark frame then, not Hyprland's artwork.
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		background_color = 0xff101010,
	},
})
