return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  build = "cd app && yarn install",
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
  end,
  ft = { "markdown" },
  config = function()
    -- Set options for markdown-preview.nvim
    vim.g.vim_markdown_folding_disabled = 1
    vim.g.vim_markdown_conceal = 0
    vim.g.vim_markdown_conceal_code_blocks = 0
    vim.g.vim_markdown_new_list_item_indent = 2
    vim.g.mkdp_theme = "dark"
    vim.g.mkdp_filetypes = { "markdown" }
  end
}
