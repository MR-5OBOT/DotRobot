-- Main Hyprland Configuration
-- Modularized configuration loading

-- Gigabyte GS25F2A (external, right of the laptop). Its EDID prefers 60Hz, which
-- is also a TV mode, so the Intel HDMI output sends limited-range RGB (grey blacks).
-- 240Hz isn't a TV mode, so it gets full-range RGB. At 240Hz, HDMI 2.0 only has
-- room for 8-bit colour. vrr = 2: adaptive sync only for fullscreen apps, which
-- avoids desktop flicker.
hl.monitor({
	output = "desc:GIGA-BYTE TECHNOLOGY CO. LTD. GS25F2A",
	mode = "1920x1080@240",
	position = "auto-right",
	scale = 1,
	vrr = 2,
})

require("lua_configs.env")
require("lua_configs.input")
require("lua_configs.theme")
require("lua_configs.animations")
require("lua_configs.windowrules")
require("lua_configs.keymaps")
require("lua_configs.autostart")
require("lua_configs.misc")
