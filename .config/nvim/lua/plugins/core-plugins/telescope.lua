return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  lazy = false,
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local actions = require('telescope.actions')

    require('telescope').setup {
      defaults = {
        file_ignore_patterns = { ".git/", "node_modules/", ".DS_Store" }, -- Patterns to ignore
        layout_config = {
          horizontal = {
            prompt_position = "bottom",  -- Position of the prompt
            preview_width = 0.55,        -- Width of the preview window
            results_width = 0.8,         -- Width of the results window
          },
        },
        prompt_prefix = "   ",          -- Custom prompt prefix
        mappings = {
          i = {
            ["<C-j>"] = actions.move_selection_next, -- Move down in insert mode
            ["<C-k>"] = actions.move_selection_previous, -- Move up in insert mode
            ["<esc>"] = actions.close, -- Close the picker
          },
          n = {
            ["<C-j>"] = actions.move_selection_next, -- Move down in normal mode
            ["<C-k>"] = actions.move_selection_previous, -- Move up in normal mode
          }
        }
      },
      pickers = {
        find_files = {
          hidden = true, -- Allow searching hidden files
          find_command = {'rg', '--files', '--hidden', '--ignore', '--glob', '!.git/*'} -- Exclude .git files
        },
      }
    }
  end,
}
