return {
  "utilyre/barbecue.nvim",
  name = "barbecue",
  version = "*",
  dependencies = {
    "SmiteshP/nvim-navic",
    "nvim-tree/nvim-web-devicons", -- optional dependency
  },
  config = function()
    require("barbecue").setup({
      attach_navic = true,    -- Attach to nvim-navic for breadcrumbs
      create_autocmd = false, -- Prevent barbecue from updating itself automatically
      theme = 'monochrome',   -- Set the theme, can be auto or any other available theme
      show_modified = true,   -- Show modified flag if file is modified
    })
  end
}
