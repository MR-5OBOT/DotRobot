/*
 * Vencord, a Discord client mod
 * Copyright (c) 2026 RyanAHayden
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

// A color per person on names in the chat and the member list, like IRC clients. Yours is the color Vencord's
// IrcColors gave it; everyone else gets one of the theme's soft colors: no red or orange, and not its blue (too
// near yours).
// shortcut: the patches are Vencord's IrcColors ones (Vencord ce9355e); if names go back to plain after a Vencord
// update, recopy them from src/plugins/ircColors/index.ts

import { hash } from "@intrnl/xxhash64";
import { UserStore } from "@webpack/common";

import { logger } from "./discord";

// mr5obot-theme.css's green-1, yellow-1 and purple-1 as hex: Discord may parse a name's color, so no var() or oklch
const OTHERS = ["#4fc6a2", "#dcba5c", "#c598e7"];

function nameColor(id?: string) {
    if (!id) return undefined;
    const h = hash(id);
    return id === UserStore.getCurrentUser()?.id ? `hsl(${h % 360n}, 100%, 70%)` : OTHERS[Number(h % BigInt(OTHERS.length))];
}

export const patches = [
    {
        find: '="SYSTEM_TAG"',
        replacement: {
            match: /(?<=colorString:\i,colorStrings:\i,colorRoleName:\i.*?}=)(\i),/,
            replace: "$self.messageNameColor($1,arguments[0]),"
        }
    },
    {
        find: "#{intl::GUILD_OWNER}),children:",
        replacement: {
            match: /(?<=roleName:\i,)colorString:/,
            replace: "colorString:$self.listNameColor(arguments[0]),originalColor:"
        }
    }
];

/** a message's author name: the color, and no role gradient over it */
export function messageNameColor(props: { colorString?: string; colorStrings?: Record<string, string | undefined>; }, context: any) {
    try {
        const colorString = nameColor(context?.message?.author?.id);
        // the role color preview in server settings keeps the role's color
        if (!colorString || context?.message?.channel_id === "1337") return props;
        return { ...props, colorString, colorStrings: props.colorStrings && { primaryColor: colorString, secondaryColor: undefined, tertiaryColor: undefined } };
    } catch (e) {
        logger.error("name color failed", e);
        return props;
    }
}

/** a name in the member list */
export function listNameColor(context: any) {
    try {
        return nameColor(context?.user?.id) ?? context?.colorString;
    } catch (e) {
        logger.error("name color failed", e);
        return context?.colorString;
    }
}
