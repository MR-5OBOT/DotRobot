local SCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"

hl.on("hyprland.start", function()
  -- Critical Services
  hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")

  -- Daemons
  hl.exec_cmd("awww-daemon")                            -- paints the wallpaper; qs only picks it
  hl.exec_cmd("qs")                                     -- launcher + clipboard + wifi/bt + menus + lock + wallpaper
  hl.exec_cmd(SCRIPTS .. "/autostart/island.sh")        -- top-edge island bar; owns notifications
  hl.exec_cmd(SCRIPTS .. "/autostart/cliphist.sh")
  hl.exec_cmd(SCRIPTS .. "/autostart/battery-notify.sh") -- low-batt nag; the island draws it as a toast
  hl.exec_cmd("devify")
  hl.exec_cmd("hypridle")
end)
