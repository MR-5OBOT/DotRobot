return {
  "folke/noice.nvim",
  event = "VeryLazy",
	dependencies = {
    -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
	},
  opts = {
	  views = {
      cmdline_popup = {
        border = {
          style = "none",
          padding = { 1, 1 },
        },
        filter_options = {},
        win_options = {
          winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
        },
      },
    },
  },
  
}
