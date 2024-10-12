#!/usr/bin/env bash
 
WINEPREFIX="/home/ys/Downloads"
DXVK_LOG_PATH="$WINEPREFIX/dxvk_cache"
DXVK_STATE_CACHE_PATH="$WINEPREFIX/dxvk_cache"
PHOTOSHOP="$WINEPREFIX/drive_c/Program Files/Adobe Photoshop 2021/photoshop.exe"
 
wine64 "$PHOTOSHOP" "$@" 
