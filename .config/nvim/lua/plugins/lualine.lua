local colors = {
  color3 = '#101010',
  color1 = '#78a9ff',
  color2 = '#E55090',
  color6 = '#42be65',
  color7 = '#ee5396',
  color8 = '#3ddbd9',
  color9 = '#636567',
  color10 = '#8F70C0'
}

local custom_theme = {
  normal = {
    a = { fg = colors.color3, bg = colors.color9 }, -- Normal mode color
    b = { fg = colors.color9, bg = 'NONE' },        -- Transparent secondary
  },
  insert = {
    a = { fg = colors.color3, bg = colors.color6 }, -- Insert mode color
  },
  visual = {
    a = { fg = colors.color3, bg = colors.color1 }, -- Visual mode color
  },
  command = {
    a = { fg = colors.color3, bg = colors.color2 }, -- Command mode color
  },
  inactive = {
    a = { fg = colors.color3, bg = 'NONE' }, -- Transparent inactive background
    b = { fg = colors.color9, bg = 'NONE' }, -- Transparent inactive background
  },
}

return {
  'nvim-lualine/lualine.nvim',
  config = function()
    require('lualine').setup {
      options = {
        icons_enabled = true,
        theme = custom_theme,
        component_separators = { left = '|', right = '|' },
        section_separators = { left = '', right = '' },
        disabled_filetypes = {
          statusline = {},
          winbar = {},
        },
        always_divide_middle = true,
        globalstatus = false,
        refresh = {
          statusline = 1000,
          tabline = 1000,
          winbar = 1000,
        },
        -- Ensure that no background is applied globally
        bg = 'NONE', -- This may be overridden by the theme
      },
      sections = {
        lualine_a = { 'mode' },   -- Show mode (Normal, Insert, etc.)
        lualine_b = { 'branch' }, -- Show git branch
        lualine_c = {},           -- Empty section
        lualine_x = {},           -- Empty section
        lualine_y = {},           -- Empty section
        lualine_z = {}            -- Optional: can add additional info here
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {}, -- Show nothing in inactive sections
        lualine_x = {},
        lualine_y = {},
        lualine_z = {}
      },
      tabline = {},
      winbar = {},
      inactive_winbar = {},
      extensions = {}
    }
  end
}
