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
        a = { fg = colors.color3, bg = colors.color9 },
        b = { fg = colors.color9, bg = 'NONE' },
    },
    insert = {
        a = { fg = colors.color3, bg = colors.color6 },
    },
    visual = {
        a = { fg = colors.color3, bg = colors.color1 },
    },
    command = {
        a = { fg = colors.color3, bg = colors.color2 },
    },
    inactive = {
        a = { fg = colors.color3, bg = 'NONE' },
        b = { fg = colors.color9, bg = 'NONE' },
    },
}

return {
    'nvim-lualine/lualine.nvim',
    config = function()
        require('lualine').setup {
            options = {
                icons_enabled = true,
                theme = custom_theme,
                component_separators = '|',
                section_separators = '',
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
            },
            sections = {
                lualine_a = { 'mode' },
                lualine_b = { 'branch' },
                lualine_c = { { 'filename', path = 1 } }, -- Center section for filename
                lualine_x = {},
                lualine_y = {},
                lualine_z = {} -- Keep this empty or add other right side components
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = {},
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
