-- Theme and General Settings

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 5,
        border_size = 4,
        col = {
            active_border = 0xff323232,
            inactive_border = 0xff323232
        },
        resize_on_border = false,
        allow_tearing = true,
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
            xray = true,
            special = false,
            new_optimizations = true,
            size = 14,
            passes = 4,
            brightness = 1,
            noise = 0.01,
            contrast = 1,
            popups = true,
            popups_ignorealpha = 0.6
        },
        shadow = {
            enabled = false,
            range = 5,
            offset = { 0, 2 },
            render_power = 1,
            color = 0xee1a1a1a
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
        font_family = "NovaMono"
    }
})
