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
        -- tiled windows, this doubles as the focus cue. Warm vermilion to match
        -- the QS accent; kept low-alpha so it reads as light, not a border.
        glow = {
            enabled = true,
            range = 16,
            render_power = 2,
            color = 0x38ff6a3d,
            color_inactive = 0x14ff6a3d,
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
