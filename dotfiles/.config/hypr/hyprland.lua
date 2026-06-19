-- Main Hyprland Configuration
-- Modularized configuration loading

require("lua_configs.env")
require("lua_configs.input")
require("lua_configs.theme")
require("lua_configs.animations")
require("lua_configs.windowrules")
require("lua_configs.keymaps")
require("lua_configs.autostart")
require("lua_configs.misc")

-- Load any specific configurations for swaync or other modules if needed
-- require("lua_configs.swaync")
