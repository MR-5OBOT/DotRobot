-- Keymaps
-- Super = system: + SHIFT moves, + CTRL resizes, + ALT extras. Alt alone belongs to apps (kitty, tmux, nvim, Brovim).

local mainMod = "SUPER"
local SCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"
local SCRIPT = SCRIPTS .. "/controls"
local RISHOT = os.getenv("HOME") .. "/.config/quickshell/rishot/bin/rishot"
local QS = require("lua_configs.qs")
local focusDir = require("lua_configs.smartfocus") -- Super+H/J/K/L
local monitorKeys = require("lua_configs.monitorkeys") -- Super+Tab keys
-- the island bar lives inside the main quickshell config (quickshell/island/)
local ISLAND = "qs ipc call island"

-- Window Management
hl.bind(mainMod .. " + X", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + C", hl.dsp.window.center())
hl.bind(mainMod .. " + ALT + Space", hl.dsp.window.float({ action = "toggle" }))
-- lockscreen: pauses whatever is playing, then hyprlock (fingerprint unlock)
local LOCK = os.getenv("HOME") .. "/.config/quickshell/island/scripts/lock.sh"
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd(LOCK))

-- Application Launchers
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("uwsm app -- kitty"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("uwsm app -- kitten quick-access-terminal")) -- shared float terminal (toggle)
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(ISLAND .. ' home ""')) -- dashboard
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(ISLAND .. ' battery ""')) -- battery
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("kitty --class nmtui -e nmtui")) -- network manager (tui)
hl.bind(mainMod .. " + ALT + I", hl.dsp.exec_cmd("nm-connection-editor")) -- full editor: hotspots, static IPs, VPNs
hl.bind(mainMod .. " + ALT + N", hl.dsp.exec_cmd("pkill -x qs; " .. QS)) -- restart quickshell (island included)
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd(ISLAND .. ' power ""'))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call wallpicker toggle"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("qs ipc call clipboard toggle"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call notifications toggle"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(ISLAND .. ' peek ""'))
hl.bind(mainMod .. " + equal", hl.dsp.exec_cmd("qs ipc call calc toggle"))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("qs ipc call keymaps toggle")) -- keymap cheat sheet

hl.bind("XF86Calculator", hl.dsp.exec_cmd("qs ipc call calc toggle"))
hl.bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd("hyprpicker -a -n"))

-- Screenshots
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(SCRIPT .. "/screenshot.sh"))
hl.bind("Print", hl.dsp.exec_cmd(RISHOT)) -- drag region or click a window
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(RISHOT)) -- same, Windows-style snip

-- Keyboard clicking (wl-kbptr grid): g = left click, h = right, Enter = move only
hl.bind(mainMod .. " + ALT + F", hl.dsp.exec_cmd("pkill -x wl-kbptr || wl-kbptr"))
-- Split mode: arrows halve the area, g/h/b = left/right/middle click, Enter = move only, Backspace = undo
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("pkill -x wl-kbptr || wl-kbptr -o modes=split"))

-- Volume & Brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(SCRIPT .. "/volume.sh --inc"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(SCRIPT .. "/volume.sh --dec"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(SCRIPT .. "/volume.sh --toggle-mic"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(SCRIPT .. "/volume.sh --toggle"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(SCRIPT .. "/brightness.sh --dec"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(SCRIPT .. "/brightness.sh --inc"), { locked = true })

-- pauses everything playing; the next press resumes those players
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("qs ipc call media toggle"))

-- Power profile picker: tap to move down the list, Enter to apply
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd("qs ipc call powerprofile cycle"))

-- Focus Navigation (smartfocus.lua also hops between floating and tiled windows)
hl.bind(mainMod .. " + H", focusDir("left"))
hl.bind(mainMod .. " + L", focusDir("right"))
hl.bind(mainMod .. " + K", focusDir("up"))
hl.bind(mainMod .. " + J", focusDir("down"))

-- Moving Windows
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

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
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Monitors (monitorkeys.lua): Tab = focus the other screen, + SHIFT = send the window
-- there, + CTRL = laptop screen off/on
hl.bind(mainMod .. " + Tab", monitorKeys.focusNext)
hl.bind(mainMod .. " + SHIFT + Tab", monitorKeys.sendWindowNext)
hl.bind(mainMod .. " + CTRL + Tab", monitorKeys.toggleLaptop)

-- Move/Resize mouse bindings
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
