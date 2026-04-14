#!/usr/bin/env bash

restart_delay=2

echo "starting clipse listener supervisor"

while true; do
    # Run the foreground listener under a loop so clipboard capture recovers after crashes/exits.
    clipse -kill >/dev/null 2>&1 || true
    clipse -listen-shell
    exit_code=$?

    echo "clipse listener exited with code ${exit_code}; restarting in ${restart_delay}s"
    sleep "${restart_delay}"
done
