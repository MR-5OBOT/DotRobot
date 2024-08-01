return {
  -- Markdown preview
  {
    "iamcco/markdown-preview.nvim",
    build = function() vim.fn["mkdp#util#install"]() end,
    cmd = { "MarkdownPreview", "MarkdownPreviewStop" },
    ft = "markdown",
    opts = {
      vim.g.vim_markdown_folding_disabled == 1,
      vim.g.vim_markdown_conceal == 0,
      vim.g.vim_markdown_conceal_code_blocks == 0,
      vim.g.vim_markdown_new_list_item_indent == 2,
      vim.g.mkdp_theme == "dark",
    }
  }
}
