#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

declare fallback=eDP-1
declare -x MONITOR

if [[ -z "$MONITOR" ]]; then
    while read -r index state geom name; do 
        if [[ "$state" == "+*"* ]]; then
            echo "Using default monitor $name"
            MONITOR=$name
        fi
    done < <(xrandr --listmonitors | sed 1d)
    if [[ -z "$MONITOR" ]]; then
        echo "Falling back to monitor $fallback"
        MONITOR=$fallback
    fi
fi

# Wait until the processes have been shut down
while pgrep -x polybar >/dev/null; do sleep 1; done

# Launch polybar
polybar bottom &
disown -ah
