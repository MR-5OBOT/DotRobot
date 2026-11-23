-- Monitors
--
-- Laptop (eDP-1): no rule, Hyprland's defaults fit it: 1920x1080@60, scale 1.5
-- (apps see 1280x720), at 0x0. Add an hl.monitor block for "eDP-1" to change it.

-- Gigabyte GS25F2A, external, right of the laptop.
-- Matched by model (desc:) instead of port, so it works on any port or dock and
-- never applies these settings to another screen on the same HDMI port.
local GIGABYTE = "desc:GIGA-BYTE TECHNOLOGY CO. LTD. GS25F2A"
-- Fullscreen HDR and content-type switches blank the external HDMI monitor.
hl.config({ render = { cm_auto_hdr = 0, send_content_type = false } })
hl.monitor({
	output = GIGABYTE,
	-- Not 60Hz: Intel treats 1080p60 over HDMI as a TV and sends limited-range
	-- colour (grey blacks). 240Hz gets full range. Max 8-bit colour over HDMI 2.0.
	-- TEST (2026-11-23 to 11-25), only to see if the monitor's sound still cuts out: at 165Hz and
	-- above (HDMI 2.0) the monitor reports lanes 1-2 unlocked with ~187k errors/s, and
	-- the sound rides on those lanes. This custom 144Hz mode stays under 340 MHz
	-- (HDMI 1.4, 0 errors) and isn't a TV mode, so it keeps full range.
	-- If the sound never cuts out at 144Hz, the link was the cause. Either way, go
	-- back to "1920x1080@240" afterwards.
	mode = "modeline 325.44 1920 1928 1960 2000 1080 1083 1088 1130 +hsync -vsync",
	position = "auto-right",
	scale = 1,
	-- No vrr: Intel offers VRR only on DisplayPort/USB-C here, not HDMI.
})

-- Workspaces 1-10 live on the Gigabyte, so apps that windowrules.lua sends to them
-- open there. The laptop uses 11+. Unplugged, 1-10 fall back to the laptop.
for i = 1, 10 do
	hl.workspace_rule({ workspace = tostring(i), monitor = GIGABYTE })
end
