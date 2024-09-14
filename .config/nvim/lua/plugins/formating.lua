return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require("conform")
    conform.setup({
      formatters_by_ft = {
        html = { "prettier" },  -- Use prettier for HTML formatting
        css = { "prettier" },   -- Use prettier for CSS formatting
        javascript = { "prettier" }, -- Use prettier for JavaScript formatting
        json = { "prettier" },  -- Use prettier for JSON formatting
        -- Add more file types and their respective formatters here
      },
      format_on_save = {
        lsp_fallback = true,
        async = false,
        timeout_ms = 500,
      },
    })
  end,
}

