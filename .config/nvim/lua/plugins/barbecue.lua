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
      create_autocmd = false, -- prevent barbecue from updating itself automatically
    })
  end
}
