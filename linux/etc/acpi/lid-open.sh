#!/bin/sh

case "$3" in
    open) 
        echo 1 > /sys/class/leds/tpacpi::kbd_backlight/brightness
        ;;
    close) ;;
    *) logger "failed to handle lid event: $3"
esac
