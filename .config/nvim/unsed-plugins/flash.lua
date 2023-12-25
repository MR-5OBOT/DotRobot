return {
  "folke/flash.nvim",
  event = "VeryLazy",
  config = function()
        require("flash").setup({})
    end,
  opts = {},
  -- stylua: ignore
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
  },
}
