return {
  'nvim-treesitter/nvim-treesitter',
  config = function ()
  require'nvim-treesitter.configs'.setup {
  	ensure_installed = {
 	  "lua",
 	  "python",
    "markdown",
    "markdown_inline",
    "css",
    "html",
    },
  	sync_install = true,
    auto_install = true,
    highlight = {
    enable = true,
    -- Some languages depend on vim's regex highlighting system (such as
    -- Ruby) for indent rules. If you are experiencing weird indenting
    -- issues, add the language to the list of additional vim regex
    -- highlighting and disabled languages for indent.
    additional_vim_regex_highlighting = { "ruby" },
  },
  }
  end
}
