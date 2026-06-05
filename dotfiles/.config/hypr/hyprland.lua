-- Main Hyprland Configuration
-- Modularized configuration loading

require("lua_configs.env")
require("lua_configs.input")
require("lua_configs.theme")
require("lua_configs.animations")
require("lua_configs.windowrules")
require("lua_configs.keymaps")
require("lua_configs.autostart")

-- Load any specific configurations for swaync or other modules if needed
-- require("lua_configs.swaync")

hl.config({
	general = {
		resize_on_border = true,
	},
})

-- HyprMod managed settings
require("hyprland-gui")
