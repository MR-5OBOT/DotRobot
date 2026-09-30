hl.config({
	misc = {
		-- apps can't raise themselves on activation (Hyprland's default), so clicking a
		-- notification won't jump to WhatsApp/Telegram. Set true if you want that.
		focus_on_activate = false,
		-- awww paints the wallpaper, so restarting it leaves the background bare for a
		-- moment. Show a dark frame then, not Hyprland's artwork.
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		background_color = 0xff101010,
	},
})
