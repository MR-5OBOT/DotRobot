-- Input Settings

hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = -0.05,
        natural_scroll = false,
        touchpad = {
            scroll_factor = 1.5,
            -- The pad is a clickpad (no real right button). Set this explicitly
            -- so Hyprland pushes button-areas to libinput; left unset, libinput
            -- defaults to clickfinger and the bottom-right corner does nothing.
            clickfinger_behavior = false,
            -- libinput was dropping taps/clicks made right after typing.
            disable_while_typing = false
        }
    }
})
