#!/usr/bin/env bash
notify-send -u low "Speedtest" "Running…"
res=$(speedtest-cli --secure --simple 2>/dev/null) || res="failed"
notify-send -u low "Speedtest" "$res"      # multiline: Ping/Download/Upload
