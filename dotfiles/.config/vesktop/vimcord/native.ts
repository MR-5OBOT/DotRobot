/*
 * Vencord, a Discord client mod
 * Copyright (c) 2026 RyanAHayden
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { BrowserWindow, IpcMainInvokeEvent } from "electron";

/** macOS's traffic lights are native, so hiding them happens here (Windows/Linux buttons are Discord's own, hidden by CSS) */
export function setWindowButtons(e: IpcMainInvokeEvent, visible: boolean) {
    BrowserWindow.fromWebContents(e.sender)?.setWindowButtonVisibility?.(visible);
}
