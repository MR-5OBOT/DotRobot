-- Keymaps

local mainMod = "SUPER"
local SCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"
local SCRIPT = SCRIPTS .. "/controls"

-- Window Management
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(mainMod .. " + C", hl.dsp.window.center())
hl.bind("ALT + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind("ALT + L", hl.dsp.exec_cmd("gtklock"))

-- Application Launchers
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("[float]kitty"))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("killall swaync && swaync"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("sh " .. SCRIPTS .. "/rofi-powermenu.sh"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("sh " .. SCRIPTS .. "/wallpapers/walls-picker.sh"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("kitty --class clipse -e 'clipse'"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a -n"))
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.exec_cmd(SCRIPTS .. "/speedtest.sh"))
hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.exec_cmd(SCRIPTS .. "/whichkey.sh"))
-- hl.bind("ALT + C", hl.dsp.exec_cmd("qalculate-gtk"))

-- Waybar Controls
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd("pkill -SIGUSR1 '^waybar$'"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("sh " .. SCRIPTS .. "/autostart/toggle-waybar.sh"))

-- Screenshots & Recording
hl.bind("Print", hl.dsp.exec_cmd("bash " .. SCRIPTS .. "/screenshot.sh menu"))

hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(SCRIPTS .. "/recording/wf-screenRE"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(SCRIPTS .. "/recording/stop-recording"))

-- Volume & Brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(SCRIPT .. "/volume.sh --inc"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(SCRIPT .. "/volume.sh --dec"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(SCRIPT .. "/volume.sh --toggle-mic"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(SCRIPT .. "/volume.sh --toggle"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(SCRIPT .. "/brightness.sh --dec"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(SCRIPT .. "/brightness.sh --inc"), { locked = true })

-- Focus Navigation
hl.config({
	binds = {
		movefocus_cycles_fullscreen = 1,
	},
})
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Moving Windows
hl.bind(mainMod .. " + ALT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + ALT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + ALT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + ALT + J", hl.dsp.window.move({ direction = "down" }))

-- Resizing Windows
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })

-- Workspaces
for i = 1, 9 do
	hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Move/Resize mouse bindings
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Thumb side buttons:
--   lower / back  (BTN_SIDE)   -> toggle mic mute
--   upper / forward (BTN_EXTRA) -> region screenshot (see alternatives below)
hl.bind("mouse:275", hl.dsp.exec_cmd(SCRIPT .. "/volume.sh --toggle-mic"))
hl.bind("mouse:276", hl.dsp.exec_cmd("bash " .. SCRIPTS .. "/screenshot.sh"))

-- Alternatives for mouse:276 -- comment out the line above and uncomment one:
-- hl.bind("mouse:276", hl.dsp.exec_cmd("gtklock"))                                           -- lock screen
-- hl.bind("mouse:276", hl.dsp.exec_cmd("kitty --class clipse -e 'clipse'"))                  -- clipboard history
-- hl.bind("mouse:276", hl.dsp.window.close())                                                -- close window
-- hl.bind("mouse:276", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })) -- fullscreen
-- hl.bind("mouse:276", hl.dsp.exec_cmd("rofi -show drun"))                                   -- launcher

-- Right-click on the bare wallpaper opens the power menu.
-- non_consuming = the click still passes through to apps/waybar normally.
hl.bind("mouse:273", hl.dsp.exec_cmd(SCRIPTS .. "/empty-rightclick.sh"), { non_consuming = true })
