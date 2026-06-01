-- Window Rules

-- Workspace assignments
hl.window_rule({ match = { class = "firefox" }, workspace = 1 })
hl.window_rule({ match = { class = "^(brave-.*)" }, workspace = 1 })
hl.window_rule({ match = { class = "kitty" }, workspace = 2 })
hl.window_rule({ match = { class = "^(org.telegram.desktop)$" }, workspace = 3 })
hl.window_rule({ match = { class = "^(gimp-.*)" }, workspace = 5 })
hl.window_rule({ match = { class = "^(com.obsproject.Studio)$" }, workspace = 6 })
hl.window_rule({ match = { class = "mpv" }, workspace = 8 })
hl.window_rule({ match = { class = "^(terminal64.exe)$" }, workspace = 4 })

-- TradingView (Brave PWA)
hl.window_rule({ match = { class = "^(brave-knojlbibkfmpiekeiifbljpfojlioonl-Default)$" }, workspace = 4 })

-- Floating rules with size/center
hl.window_rule({ match = { class = "kitty" }, float = true, center = true, size = "620 360" })
hl.window_rule({ match = { class = "^(qalculate-gtk)$" }, float = true, center = true, size = "700 600" })
hl.window_rule({ match = { class = "^(thunar)$" }, float = true, center = true, size = "700 600" })
hl.window_rule({
	match = { class = "hyprland-share-picker" },
	float = true,
	center = true,
	size = "600 400",
	pin = true,
})
hl.window_rule({ match = { class = "nwg-look" }, float = true, center = true, size = "500 400", pin = true })
hl.window_rule({ match = { class = "clipse" }, float = true, center = true, size = "522 552" })

-- Floating utilities and dialogs
local float_classes = {
	"Tk",
	"thunar",
	"pavucontrol",
	"nm-connection-editor",
	"blueman-manager",
	"file-roller",
	"mpv",
	"org.kde.polkit-kde-authentication-agent-1",
	"vlc",
	"kvantummanager",
	"qt5ct",
	"qt6ct",
	"nwg-look",
}
for _, cls in ipairs(float_classes) do
	hl.window_rule({ match = { class = "^(" .. cls .. ")$" }, float = true })
end

hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true, pin = true })
hl.window_rule({ match = { title = "^(Media viewer)$" }, float = true })
hl.window_rule({ match = { title = "^(Volume Control)$" }, float = true })
hl.window_rule({ match = { class = "^(Picture-in-Picture)$" }, float = true })
hl.window_rule({ match = { class = "^(Viewnior)$" }, float = true })
hl.window_rule({ match = { class = "^(file_progress)$" }, float = true })
hl.window_rule({ match = { class = "^(confirm)$" }, float = true })
hl.window_rule({ match = { class = "^(dialog)$" }, float = true })
hl.window_rule({ match = { class = "^(download)$" }, float = true })
hl.window_rule({ match = { class = "^(notification)$" }, float = true })
hl.window_rule({ match = { class = "^(error)$" }, float = true })
hl.window_rule({ match = { title = "^(Open File)$" }, float = true })
hl.window_rule({ match = { title = "^(File Operation Progress)$" }, float = true })
hl.window_rule({ match = { class = "^(Confirm to replace files)$" }, float = true })
hl.window_rule({ match = { class = "^(File Operation Progress)$" }, float = true })

-- File dialogs
hl.window_rule({
	match = { title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files)$" },
	float = true,
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
