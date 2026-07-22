-- Environment Variables

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
-- Qt widgets are themed by qt6ct (Qt6) / qt5ct (Qt5): style + palette live in
-- ~/.config/qt6ct/ and ~/.config/qt5ct/ (colors/paradise.conf matches the GTK theme).
-- QML apps (e.g. hyprpolkitagent) use the Fusion QML style, which follows that palette.
hl.env("QT_QUICK_CONTROLS_STYLE", "Fusion")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")

hl.env("CLUTTER_BACKEND", "wayland")

hl.env("XCURSOR_THEME", "volantes_light_cursors")
hl.env("XCURSOR_SIZE", "26")

-- Dark Theme
hl.env("GTK_THEME", "paradise")
hl.env("COLOR_SCHEME", "prefer-dark")

hl.config({
	xwayland = {
		force_zero_scaling = true,
	},
})
