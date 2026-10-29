-- Window Rules

-- Workspace assignments
hl.window_rule({ match = { class = "^(helium)$" }, workspace = 1 })
hl.window_rule({ match = { class = "kitty" }, workspace = 2 })
hl.window_rule({ match = { class = "^(obs|com.obsproject.Studio)$" }, workspace = 6 })
hl.window_rule({ match = { class = "(?i)^(org.kde.kdenlive|kdenlive)$" }, workspace = 3 })
hl.window_rule({ match = { class = "(?i)^(org[.]kde[.]krita|krita)$" }, workspace = 3 })
hl.window_rule({ match = { class = "(?i).*tradingview.*" }, workspace = 4 })
hl.window_rule({ match = { title = "(?i).*tradingview.*" }, workspace = 4 })
hl.window_rule({ match = { class = "(?i)^gimp.*$" }, workspace = 5 })
hl.window_rule({ match = { class = "(?i)^(blender|org[.]blender[.]blender)$" }, workspace = 7 })

-- Floating rules with size/center
hl.window_rule({
	match = { initial_title = "^_crx_[a-p]{32}$" },
	float = true,
	center = true,
	size = "480 600",
})
hl.window_rule({ match = { class = "kitty" }, float = true, center = true, size = "620 360" })
hl.window_rule({ match = { class = "^(nemo)$" }, float = true, center = true, size = "700 600" })
hl.window_rule({
	match = { class = "hyprland-share-picker" },
	float = true,
	center = true,
	size = "600 400",
	pin = true,
})
hl.window_rule({ match = { class = "nwg-look" }, float = true, center = true, size = "500 400", pin = true })

-- Kdenlive popups & dialogs: ensure good size and centered
hl.window_rule({
	match = { class = "(?i)^(org.kde.kdenlive|kdenlive)$", float = true },
	center = true,
	min_size = "850 550",
})
hl.window_rule({
	match = { class = "(?i)^(org.kde.kdenlive|kdenlive)$", title = "(?i).*Title Clip.*" },
	float = true,
	center = true,
	size = "1100 660",
})
hl.window_rule({
	match = { class = "(?i)^(org.kde.kdenlive|kdenlive)$", title = "(?i).*(Render|Project Settings|Configure).*" },
	float = true,
	center = true,
	size = "1000 640",
})

local float_classes = {
	"Tk",
	"pavucontrol",
	"nm-connection-editor",
	"blueman-manager",
	"file-roller",
	"qt5ct",
}
for _, cls in ipairs(float_classes) do
	hl.window_rule({ match = { class = "^(" .. cls .. ")$" }, float = true })
end

local float_titles = {
	"Media viewer",
	"Volume Control",
	"File Operations",
}
for _, t in ipairs(float_titles) do
	hl.window_rule({ match = { title = "^(" .. t .. ")$" }, float = true })
end

-- File dialogs
-- The GTK/Qt portal file chooser is a separate client; without an explicit size it
-- opens at its own default (~1203x978), which overflows a 1280x720 logical screen.
hl.window_rule({
	match = { class = "^(xdg-desktop-portal-gtk|xdg-desktop-portal-hyprland)$" },
	float = true,
	center = true,
	size = "900 560",
})
hl.window_rule({
	match = { title = "^(Open.*Files?|Open [Ff]older.*|Save.*Files?|Save.*As|Save|All Files)$" },
	float = true,
	center = true,
	size = "900 560",
})

-- Shadows on floating windows only: decoration.shadow is on, this strips it from
-- tiled windows. Shadow colours match the old border colours.
hl.window_rule({ match = { float = false }, no_shadow = true })

-- Floating windows already get a shadow; glow on top of it reads as a giant
-- halo around dialogs (file pickers, OBS properties). Keep glow for tiled
-- windows only, where it is the focus cue.
hl.window_rule({ match = { float = true }, no_glow = true })

-- Animation opt-outs: precision tools and video players get no wobble and no
-- glow, so dragging a mask/playhead or resizing a preview stays predictable.
local calm_classes = {
	"org[.]kde[.]kdenlive",
	"kdenlive",
	"org[.]kde[.]krita",
	"krita",
	"org[.]blender[.]blender",
	"blender",
	"gimp.*",
	"org[.]obsproject[.]Studio",
	"obs",
	"mpv",
	"vlc",
}
for _, cls in ipairs(calm_classes) do
	hl.window_rule({ match = { class = "^(" .. cls .. ")$" }, no_wobble = true, no_glow = true })
end
