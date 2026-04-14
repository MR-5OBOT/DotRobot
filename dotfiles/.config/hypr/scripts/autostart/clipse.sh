#!/usr/bin/env bash

restart_delay=2
health_check_delay=1
poll_interval=15
clipse_bin="$(command -v clipse)"

if [[ -z "${clipse_bin}" ]]; then
    echo "clipse binary not found"
    exit 1
fi

listener_is_running() {
    pgrep -u "${UID}" -f "^wl-paste .*--watch ${clipse_bin} --wl-store$" >/dev/null
}

start_listener() {
    clipse -listen >/dev/null 2>&1
}

echo "starting clipse listener supervisor"

while true; do
    if listener_is_running; then
        sleep "${poll_interval}"
        continue
    fi

    echo "clipse listener missing; starting background listener"

    if start_listener; then
        sleep "${health_check_delay}"

        if listener_is_running; then
            echo "clipse listener started"
            sleep "${poll_interval}"
            continue
        fi
    fi

    echo "clipse listener failed to start; retrying in ${restart_delay}s"
    sleep "${restart_delay}"
done
