-- Monitors
--
-- Laptop (eDP-1): no rule, Hyprland's defaults fit it: 1920x1080@60, scale 1.5
-- (apps see 1280x720), at 0x0. Add an hl.monitor block for "eDP-1" to change it.

-- Gigabyte GS25F2A, external, right of the laptop.
-- Matched by model (desc:) instead of port, so it works on any port or dock and
-- never applies these settings to another screen on the same HDMI port.
local GIGABYTE = "desc:GIGA-BYTE TECHNOLOGY CO. LTD. GS25F2A"
hl.monitor({
	output = GIGABYTE,
	-- Not 60Hz: Intel treats 1080p60 over HDMI as a TV and sends limited-range
	-- colour (grey blacks). 240Hz gets full range. Max 8-bit colour over HDMI 2.0.
	mode = "1920x1080@240",
	position = "auto-right",
	scale = 1,
	vrr = 2, -- FreeSync in fullscreen apps only; always-on flickers the desktop
})

-- Workspaces 1-10 live on the Gigabyte, so apps that windowrules.lua sends to them
-- open there. The laptop uses 11+. Unplugged, 1-10 fall back to the laptop.
for i = 1, 10 do
	hl.workspace_rule({ workspace = tostring(i), monitor = GIGABYTE })
end
