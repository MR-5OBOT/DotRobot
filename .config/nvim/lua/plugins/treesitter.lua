return {
  'nvim-treesitter/nvim-treesitter',
  config = function ()
  require'nvim-treesitter.configs'.setup {
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
        },
  	sync_install = true,
  	auto_install = true,
  	highlight = {
  	enable = true,
      additional_vim_regex_highlighting = { "markdown" },
  	}
  }
  end
}
