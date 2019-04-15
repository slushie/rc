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

case $(nmcli -g general.state con show 'Corporate LAN') in
    "")             colorize 1 "" ;;
    "activating")   colorize 2 "" ;;
    "activated")    colorize 3 "" ;;
esac
