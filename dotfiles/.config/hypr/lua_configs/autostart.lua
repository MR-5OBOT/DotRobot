local SCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"

hl.on("hyprland.start", function()
  -- Critical Services
  hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")

  -- Daemons
  hl.exec_cmd("awww-daemon")                            -- paints the wallpaper; qs only picks it
  -- one quickshell: the island bar (owns notifications) + launcher, clipboard, wifi/bt, menus.
  -- MALLOC_CONF lets jemalloc hand freed memory back instead of holding the session peak.
  hl.exec_cmd("env MALLOC_CONF=background_thread:true,dirty_decay_ms:100,muzzy_decay_ms:100 qs")
  hl.exec_cmd(SCRIPTS .. "/autostart/cliphist.sh")
  hl.exec_cmd(SCRIPTS .. "/autostart/battery-notify.sh") -- low-batt nag; the island draws it as a toast
  hl.exec_cmd("devify")
  hl.exec_cmd("hypridle")
end)
