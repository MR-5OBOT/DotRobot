-- Theme and General Settings

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 5,
        border_size = 0,
        resize_on_border = false,
        hover_icon_on_border = true,
        snap = {
            enabled = true,
            respect_gaps = true,
        },
    },
    decoration = {
        rounding = 0,
        blur = {
            enabled = false,
        },
        shadow = {
            enabled = true,
            range = 12,
            offset = { 0, 0 },
            render_power = 3,
            color = 0xff4e1a30,
            color_inactive = 0xff33101e
        }
    },
    group = {
        groupbar = {
            enabled = true,
            font_size = 12,
            height = 16,
            text_color = 0xffffffff,
            col = {
                active = 0x808080FF,
                inactive = 0x66777700,
                locked_active = 0x66ff5500,
                locked_inactive = 0x66775500
            }
        }
    },
    misc = {
        font_family = "IosevkaTerm Nerd Font"
    }
})
