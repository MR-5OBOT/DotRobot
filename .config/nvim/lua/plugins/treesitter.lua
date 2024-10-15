return {
  'nvim-treesitter/nvim-treesitter',
  config = function()
    require 'nvim-treesitter.configs'.setup {
      ensure_installed = {
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "css",
        "python",
        "tsx",
        "typescript",
        "vim",
        "yaml",
        "hyprlang"
      },
      sync_install = true,
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { "markdown" },
      },
      -- the following code snippet for automatic filetype detection for hyprland configs
      vim.filetype.add({
        pattern = { [".*/hypr/.*%.conf"] = "hyprlang" },
      })
    }
  end
}
