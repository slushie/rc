#!/bin/bash
ID=$(xdpyinfo | grep focus | cut -f4 -d " ")
PID=$(($(xprop -id $ID | grep -m 1 PID | cut -d " " -f 3) + 2))
if [ -e "/proc/$PID/cwd" ]
then
    exec x-terminal-emulator -cd $(readlink /proc/$PID/cwd) "$@"
else
    exec x-terminal-emulator "$@"
fi
