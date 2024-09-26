return {
  "rcarriga/nvim-notify",
  config = function()
    local notify = require("notify")
    local default = {
      -- stages = "fade_in_slide_out",
      -- render = "minimal",
      timeout = 1000,
      -- minimum_width = 18,
      icons = {
        ERROR = "",
        WARN = "",
        INFO = "",
        DEBUG = "",
        TRACE = "",
      },
    }

    notify.setup(default)

    -- Set custom border colors for each type of notification
    vim.cmd [[highlight NotifyERRORBorder guifg=#E95193]]
    vim.cmd [[highlight NotifyINFOBorder guifg=#72716E]]

    -- Remove background color from all types of notifications
    vim.cmd [[highlight NvimNotifyNormal guibg=#000000]]
    vim.cmd [[highlight NvimNotifyInfo guibg=#000000]]
    vim.cmd [[highlight NvimNotifyWarning guibg=#000000]]
    vim.cmd [[highlight NvimNotifyError guibg=#000000]]
    vim.cmd [[highlight NvimNotifyDebug guibg=#000000]]
    vim.cmd [[highlight NvimNotifyTrace guibg=#000000]]
  end,
}
