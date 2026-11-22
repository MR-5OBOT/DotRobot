/*
 * Vencord, a Discord client mod
 * Copyright (c) 2026 RyanAHayden
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { definePluginSettings } from "@api/Settings";
import { OptionType, PluginNative } from "@utils/types";

import * as cursor from "./cursor";
import { logger } from "./discord";
import * as panes from "./panes";

const Native = VencordNative.pluginHelpers.VimCord as PluginNative<typeof import("./native")>;

function applyHidden() {
    panes.setHidden({ servers: settings.store.hideServers, channels: settings.store.hideChannels });
    document.body.classList.toggle("vimcord-hide-header", settings.store.hideHeader);
}

/** hides or shows the window's own buttons: macOS's traffic lights natively, Windows/Linux's (Discord's) with CSS */
export function windowButtons(visible: boolean) {
    document.body.classList.toggle("vimcord-hide-winbuttons", !visible);
    if (navigator.platform.startsWith("Mac")) Native.setWindowButtons(visible).catch(e => logger.error("window buttons", e));
}

export function onResize() {
    const w = settings.store.autoHideWidth;
    panes.setNarrow(w > 0 && window.innerWidth < w);
}

let onSettingsChange = () => { };
export const setOnSettingsChange = (fn: () => void) => void (onSettingsChange = fn);

export const settings = definePluginSettings({
    hideChannels: {
        type: OptionType.BOOLEAN,
        description: "Hide the channel list (Space e). Pressing 2 shows it while it's focused",
        default: false,
        onChange: applyHidden,
    },
    hideServers: {
        type: OptionType.BOOLEAN,
        description: "Hide the server list (Space u s). Pressing 1 shows it while it's focused",
        default: false,
        onChange: applyHidden,
    },
    hideHeader: {
        type: OptionType.BOOLEAN,
        description: "Hide the channel header (name, pins, members, search) above the chat (Space u h). It shows while its search is in use",
        default: true,
        onChange: applyHidden,
    },
    hideWindowButtons: {
        type: OptionType.BOOLEAN,
        description: "Hide the window's close/minimize/maximize buttons (macOS traffic lights too); close with the keyboard instead",
        default: true,
        onChange: (v: boolean) => windowButtons(!v),
    },
    autoHideWidth: {
        type: OptionType.NUMBER,
        description: "Hide the channel and member lists while the window is narrower than this many pixels, so the chat gets the room (2 and 4 still show them). 0 turns it off",
        default: 1000,
        onChange: () => onResize(),
    },
    statusBar: {
        type: OptionType.BOOLEAN,
        description: "Show the bottom bar with the mode (NORMAL / INSERT), focused pane and keys typed so far",
        default: true,
        onChange: () => onSettingsChange(),
    },
    statusBarHints: {
        type: OptionType.BOOLEAN,
        description: "Show hints for what you can press in the bottom bar",
        default: true,
        onChange: () => onSettingsChange(),
    },
    scrollOff: {
        type: OptionType.NUMBER,
        description: "Pixels of context kept above and below the message cursor when scrolling (like vim's scrolloff)",
        default: 80,
        onChange: (v: number) => cursor.setScrollOff(v),
    },
    whichKeyDelay: {
        type: OptionType.NUMBER,
        description: "Milliseconds before the popup listing what can follow a prefix (g, y, Space...) shows. -1 never shows it",
        default: 300,
    },
    swallowUnmapped: {
        type: OptionType.BOOLEAN,
        description: "Ignore unmapped letters when not typing, instead of Discord starting a message with them. Press i to type",
        default: true,
    },
    discordKeyboardMode: {
        type: OptionType.BOOLEAN,
        description: "Let Discord's keyboard mode stay on (Tab hopping between buttons, with focus outlines). Off: Tab cycles vimcord's panes, and the outlines stay away",
        default: false,
    },
    escapeLeavesInput: {
        type: OptionType.BOOLEAN,
        description: "Esc in the message box goes to normal mode, keeping the draft and any reply (open suggestions and popups still close first)",
        default: true,
    },
});

export { applyHidden };
