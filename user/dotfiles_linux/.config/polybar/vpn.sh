#!/bin/bash

color_1=$1
color_2=$2
color_3=$3

colorize () {
    var=color_${1}
    color=${!var}
    shift
    icon="$1"
    shift
    text="$@"
    [[ -n "$color" ]] && icon="%{F$color}$icon%{F-}"
    echo "$icon" $text
}

while IFS=: read type state name; do
    [[ "$type" == "vpn" ]]  || continue
    [[ -n "$state" ]]       || continue
    case "$state" in
    "activating")   colorize 2 "" "$name" ;;
    "activated")    colorize 3 "" "$name" ;;
    esac
    exit
done < <(nmcli -t -f type,state,name con show | sort)

colorize 1 "" off


