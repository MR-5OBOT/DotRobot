return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "kyazdani42/nvim-web-devicons",
    },
    config = function()
        -- Eviline config for lualine
        -- Author: shadmansaleh
        -- Credit: glepnir
        local lualine = require('lualine')

        -- Color table for highlights
        -- stylua: ignore
        local colors = {
            bg       = '#161616',
            fg       = '#ffffff',
            yellow   = '#f1c21b',
            cyan     = '#3ddbd9',
            darkblue = '#0f62fe',
            green    = '#42be65',
            orange   = '#ff832b',
            violet   = '#A782E0',
            magenta  = '#ff7eb6',
            blue     = '#78a9ff',
            red      = '#E45090',
        }

        local conditions = {
            buffer_not_empty = function()
                return vim.fn.empty(vim.fn.expand('%:t')) ~= 1
            end,
            hide_in_width = function()
                return vim.fn.winwidth(0) > 80
            end,
            check_git_workspace = function()
                local filepath = vim.fn.expand('%:p:h')
                local gitdir = vim.fn.finddir('.git', filepath .. ';')
                return gitdir and #gitdir > 0 and #gitdir < #filepath
            end,
        }

        -- Config
        local config = {
            options = {
                globalstatus = true, -- Set the statusline to be global
                component_separators = '',
                section_separators = '',
                theme = {
                    normal = { c = { fg = colors.fg, bg = colors.bg } },
                    inactive = { c = { fg = colors.fg, bg = colors.bg } },
                },
            },
            sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_y = {},
                lualine_z = {},
                lualine_c = {},
                lualine_x = {},
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_y = {},
                lualine_z = {},
                lualine_c = {},
                lualine_x = {},
            },
        }

        -- Inserts a component in lualine_c at the left section
        local function ins_left(component)
            table.insert(config.sections.lualine_c, component)
        end

        -- Inserts a component in lualine_x at the right section
        local function ins_right(component)
            table.insert(config.sections.lualine_x, component)
        end

        ins_left {
            function()
                return '▊'
            end,
            color = { fg = colors.violet },
            padding = { left = 0, right = 1 },
        }

        ins_left {
            -- mode component
            function()
                return ''
            end,
            color = function()
                local mode_color = {
                    n = colors.blue,
                    i = colors.green,
                    v = colors.violet,
                    [''] = colors.blue,
                    V = colors.blue,
                    c = colors.magenta,
                    no = colors.red,
                    s = colors.orange,
                    S = colors.orange,
                    [''] = colors.orange,
                    ic = colors.yellow,
                    R = colors.violet,
                    Rv = colors.violet,
                    cv = colors.red,
                    ce = colors.red,
                    r = colors.cyan,
                    rm = colors.cyan,
                    ['r?'] = colors.cyan,
                    ['!'] = colors.red,
                    t = colors.red,
                }
                return { fg = mode_color[vim.fn.mode()] }
            end,
            padding = { right = 1 },
        }

        ins_left {
            'filename',
            cond = conditions.buffer_not_empty,
            color = { fg = colors.red, gui = 'bold' },
        }

        ins_left {
            'diagnostics',
            sources = { 'nvim_diagnostic' },
            symbols = { error = ' ', warn = ' ', info = ' ' },
            diagnostics_color = {
                color_error = { fg = colors.red },
                color_warn = { fg = colors.yellow },
                color_info = { fg = colors.cyan },
            },
        }

        ins_left {
            'branch',
            icon = '',
            color = { fg = colors.violet, gui = 'bold' },
        }

        ins_left {
            function()
                return '%='
            end,
        }

        ins_left {
            -- LSP server name
            function()
                local msg = 'No Active Lsp'
                local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
                local clients = vim.lsp.get_active_clients()
                if next(clients) == nil then
                    return msg
                end
                for _, client in ipairs(clients) do
                    local filetypes = client.config.filetypes
                    if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
                        return client.name
                    end
                end
                return msg
            end,
            icon = ' LSP:',
            color = { fg = colors.violet, gui = 'bold' },
        }

        ins_right {
            'fileformat',
            fmt = string.upper,
            icons_enabled = false,
            color = { fg = colors.green, gui = 'bold' },
        }

        ins_right { 'location', color = { fg = "#7D8083" } }

        ins_right { 'progress', color = { fg = "#7D8083" } }

        ins_right {
            'diff',
            symbols = { added = ' ', modified = '󰝤 ', removed = ' ' },
            diff_color = {
                added = { fg = colors.green },
                modified = { fg = colors.orange },
                removed = { fg = colors.red },
            },
            cond = conditions.hide_in_width,
        }

        ins_right {
            function()
                return '▊'
            end,
            color = { fg = colors.violet },
            padding = { left = 1 },
        }

        -- Initialize lualine
        lualine.setup(config)
    end
}
