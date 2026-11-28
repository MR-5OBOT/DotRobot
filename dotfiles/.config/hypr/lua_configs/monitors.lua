-- Monitors. Positions are in scaled pixels.

-- Laptop: 1920x1080@60 at scale 1.5, on the left.
hl.monitor({ output = "eDP-1", position = "0x0", scale = 1.5 })

-- Gigabyte GS25F2A on the right. Matched by model, so it works on any port.
local GIGABYTE = "desc:GIGA-BYTE TECHNOLOGY CO. LTD. GS25F2A"
-- Stops fullscreen apps from blanking the monitor (HDR / content-type switches).
hl.config({ render = { cm_auto_hdr = 0, send_content_type = false } })
hl.monitor({
	output = GIGABYTE,
	-- Not 60Hz: at 1080p60 Intel sends grey blacks (limited range).
	mode = "1920x1080@240",
	-- Sound cutting out = HDMI link failing at 240Hz, likely the cable. Then use 144Hz:
	-- mode = "modeline 325.44 1920 1928 1960 2000 1080 1083 1088 1130 +hsync -vsync",
	-- Fixed, so it stays put when the laptop screen turns off. 1280 = 1920 / 1.5.
	position = "1280x0",
	scale = 1,
	-- No VRR: Intel only does it over DisplayPort / USB-C.
})

-- Workspaces 1-10 on the monitor, 11+ on the laptop.
for i = 1, 10 do
	hl.workspace_rule({ workspace = tostring(i), monitor = GIGABYTE })
end
