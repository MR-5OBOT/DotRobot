return {
  "rcarriga/nvim-notify",
  config = function()
  local notify = require("notify")
  local default = {
  -- background_colour = "#000000",
	stages = "fade",
	render = "default",
	timeout = 2000,
	minimum_width = 40,
	icons = {
		ERROR = "",
		WARN = "",
		INFO = "",
		DEBUG = "",
		TRACE = "",
	},
}

notify.setup(default)

vim.notify = function(msg, level, opts)
	notify(msg, level, opts)
end

function _G.P(...)
	print(vim.inspect(...))
	return ...
end

vim.notify = require("notify")
  end,
}
