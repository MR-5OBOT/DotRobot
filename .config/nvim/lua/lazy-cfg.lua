
-- ██╗      █████╗ ███████╗███████╗██╗   ██╗           ███╗   ██╗██╗   ██╗██╗███╗   ███╗
-- ██║     ██╔══██╗╚══███╔╝╚══███╔╝╚██╗ ██╔╝           ████╗  ██║██║   ██║██║████╗ ████║
-- ██║     ███████║  ███╔╝   ███╔╝  ╚████╔╝            ██╔██╗ ██║██║   ██║██║██╔████╔██║
-- ██║     ██╔══██║ ███╔╝   ███╔╝    ╚██╔╝             ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
-- ███████╗██║  ██║███████╗███████╗   ██║       ██╗    ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
-- ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝       ╚═╝    ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

 { import = "plugins.core-plugins" },
 { import = "plugins.lualine" },
 { import = "plugins.lsp" },
 { import = "plugins.UI" },
 { import = "plugins.UX" },
 { import = "plugins.others" },

})

performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  }
