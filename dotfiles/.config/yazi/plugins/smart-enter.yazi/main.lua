--- @sync entry
-- Enter on a directory -> enter it; on a file -> open it. Never xdg-open a dir.
return {
	entry = function()
		local h = cx.active.current.hovered
		local cmd = h and h.cha.is_dir and "enter" or "open"
		-- ponytail: emit fn was renamed across yazi versions; pick whatever exists
		local emit = ya.emit or ya.mgr_emit or ya.manager_emit
		emit(cmd, { hovered = true })
	end,
}
