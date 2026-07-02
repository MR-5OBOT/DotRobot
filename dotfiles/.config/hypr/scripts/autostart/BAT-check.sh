#!/usr/bin/env bash
# Low-battery notifier. Exits quietly on desktops (no battery / no acpi).

command -v acpi >/dev/null 2>&1 || exit 0
acpi -b 2>/dev/null | grep -q 'Battery' || exit 0   # no battery -> nothing to watch

while true; do
    pct=$(acpi -b 2>/dev/null | grep -oP '\d+%' | head -n1 | tr -d '%')
    status=$(acpi -b 2>/dev/null | head -n1)

    if [[ -n "$pct" && "$pct" -lt 10 && "$status" != *Charging* ]]; then
        notify-send -u critical "⚠️ Low Battery" "$status - Plug in your charger!"
    fi

    sleep 300
done
