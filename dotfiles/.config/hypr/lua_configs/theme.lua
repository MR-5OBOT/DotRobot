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
            color = 0xff4c1a59,
            color_inactive = 0xff2e1036
        },
        -- Compiz-style ripple while moving/resizing. Stock intensity is 0.2;
        -- 0.35 is clearly visible on the 240Hz screen without turning precise
        -- drags into guesswork. Apps that need pixel accuracy opt out via
        -- `no_wobble` in windowrules.lua.
        wobble = {
            enabled = true,
            mesh = 20,
            stiffness = 260,
            damping = 26,
            mass = 1.0,
            intensity = 0.35,
        },
        -- Active-window bloom. With border_size = 0 and shadows stripped from
        -- tiled windows, this doubles as the focus cue. Purple complements
        -- the GTK accent; low alpha keeps it subtle.
        glow = {
            enabled = true,
            range = 8,
            render_power = 3,
            color = 0x287b398e,
            color_inactive = 0x0a7b398e,
        },
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
