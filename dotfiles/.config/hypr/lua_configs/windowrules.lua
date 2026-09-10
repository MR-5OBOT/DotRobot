-- Window Rules

-- Workspace assignments
hl.window_rule({ match = { class = "^(brave-.*|helium)$" }, workspace = 1 })
hl.window_rule({ match = { class = "kitty" }, workspace = 2 })
hl.window_rule({ match = { class = "^(org.telegram.desktop)$" }, workspace = 3 })
hl.window_rule({ match = { class = "^(vesktop)$" }, workspace = 4 })
hl.window_rule({ match = { class = "^(terminal64.exe)$" }, workspace = 5 })
hl.window_rule({ match = { class = "^(Foliate)$" }, workspace = 6 })

-- Anything without a workspace rule above -> workspace 9
-- hl.window_rule({
-- 	match = { class = "negative:^(brave-.*|kitty|org.telegram.desktop|vesktop|terminal64.exe|Foliate)$" },
-- 	workspace = 9,
-- })

-- Floating rules with size/center
hl.window_rule({ match = { class = "kitty" }, float = true, center = true, size = "620 360" })
hl.window_rule({ match = { title = "^(Calculator)$" }, float = true, center = true, size = "280 340" })
hl.window_rule({ match = { title = "^(Calendar)$" }, float = true, center = true })
hl.window_rule({ match = { class = "^([Tt]hunar)$" }, float = true, center = true, size = "700 600" })
hl.window_rule({
	match = { class = "hyprland-share-picker" },
	float = true,
	center = true,
	size = "600 400",
	pin = true,
})
hl.window_rule({ match = { class = "nwg-look" }, float = true, center = true, size = "500 400", pin = true })

local float_classes = {
	"Tk",
	"pavucontrol",
	"nm-connection-editor",
	"blueman-manager",
	"file-roller",
	"org.kde.polkit-kde-authentication-agent-1",
	"vlc",
	"kvantummanager",
	"qt5ct",
	"Picture-in-Picture",
	"Viewnior",
	"file_progress",
	"confirm",
	"dialog",
	"download",
	"notification",
	"error",
	"Confirm to replace files",
	"File Operation Progress",
}
for _, cls in ipairs(float_classes) do
	hl.window_rule({ match = { class = "^(" .. cls .. ")$" }, float = true })
end

local float_titles = {
	"Media viewer",
	"Volume Control",
	"File Operation Progress",
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
	match = { title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files)$" },
	float = true,
	center = true,
	size = "900 560",
})

-- XWayland video bridge
hl.window_rule({
	match = { class = "^(xwaylandvideobridge)$" },
	opacity = "0.0 override",
	no_anim = true,
	no_initial_focus = true,
	max_size = "1 1",
	no_blur = true,
})
