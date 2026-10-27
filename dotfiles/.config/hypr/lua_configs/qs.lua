-- How the quickshell desktop shell is started: at login (autostart.lua) and by
-- the Super+Shift+N restart (keymaps.lua). MALLOC_CONF lets jemalloc hand freed
-- memory back instead of holding the session peak.
return "env MALLOC_CONF=background_thread:true,dirty_decay_ms:100,muzzy_decay_ms:100 qs"
