return {
    "prettier/vim-prettier",
    event = "BufWritePre",
    run = ":Prettier",
    opts = {
      filetypes = { "markdown" },
    },
  }
