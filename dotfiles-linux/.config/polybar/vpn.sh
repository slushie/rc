#!/bin/bash

color_1=$1
color_2=$2
color_3=$3

colorize () {
    var=color_${1}
    color=${!var}
    shift
    text="$@"
    [[ -n "$color" ]] && text="%{F$color}$text%{F-}"
    echo $text
}

nmcli -t -f type,uuid,state con show |
while IFS=: read type uuid state; do
    [[ "$type" == "vpn" ]]  || continue
    [[ -n "$state" ]]       || continue
    case "$state" in
    "activating")   colorize 2 "" ;;
    "activated")    colorize 3 "" ;;
    esac
    exit
done

colorize 1 ""


