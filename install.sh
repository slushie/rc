#!/bin/bash
# this is the main installation script

set -efu

: ${STOW_OPTS:=}
cd "$(dirname "${BASH_SOURCE[0]}")"

usage () {
    cat >&2 <<EOF
Usage:
    $0 [options] [package...]

Where options are:
    -h          show this help
    -n          perform a dry-run
    -v          debug shell output
    -y          assume yes, don't draw the menu

And packages are directory names starting with one of:
    user/       for packages which install to \$HOME ($HOME)
    system/     for packages which install to root and require sudo

Selected packages are stored in the packages.txt file and re-used
when no packages are specified on the command line.

Note that this script will fail if it cannot find its dependencies:
    stow        for symlink management
    whiptail    for drawing menus on linux
    dialog      for drawing menus on mac or linux

EOF
}

log () { echo >&2 "$@"; }

install () {
    local pkg="$1"
    local target="$2"
    local bin="${3:-}"
    local dry_run="${4:-}"

    [[ -d "$pkg" ]] || return 1
    if [[ -x "$pkg.preinstall" ]]; then
        $dry_run ./$pkg.preinstall "$target" || return 2
    fi
    $dry_run $bin stow $STOW_OPTS -S --no-folding -t "$target" "$pkg"
    if [[ -x "$pkg.postinstall" ]]; then
        $dry_run ./$pkg.postinstall "$target" && return 0
        log "ERROR: $pkg postinstall failed, rolling back."
        $dry_run $bin stow $STOW_OPTS -D --no-folding -t "$target" "$pkg"
        return 2
    fi
    return 0
}

declare -a found_packages=() want_packages=()

draw_menu () {
    local -a menu_options menu_packages
    local status title menu_width menu_output=`mktemp`
    trap "rm -f '$menu_output'" EXIT

    : ${COLUMNS:=80}
    : ${LINES:=22}

    menu_width=$(( $COLUMNS > 80 ? 80 : $COLUMNS ))

    for pkg in "${found_packages[@]}"; do
        ( printf '%s\0' "${want_packages[@]}" | grep -Fxzq -- "$pkg" ) \
            && status="on" || status="off"
        
        title="$(cut -d/ -f2 <<< "$pkg")"
        [[ "$pkg" == system/* ]] \
            && title="System package '$title' (requires sudo)" \
            || title="User package '$title'"
        title="$(printf "%-$(( menu_width - 14 ))s" "$title")"

        menu_options+=( "$pkg" "$title" $status )
    done

    whiptail --separate-output --title 'Install Packages' --notags \
        --checklist "Available Packages" $(( $LINES - 5 )) $menu_width $(( $LINES - 10 )) \
        "${menu_options[@]}" \
        2>$menu_output >/dev/tty
    
    want_packages=( $(cat "$menu_output") )
}

####
## Parse script args

declare dry_run= skip_menu=
if [[ $# -gt 0 ]]; then
    while getopts "hnvy" arg; do
        case "$arg" in
            n) log "Dry run mode, commands printed but not run."; dry_run="log" ;;
            v) set -x ;;
            y) skip_menu=1 ;; 
            h) usage; exit 0 ;;
            \?) log; usage; exit 1 ;;
        esac
    done

    shift $(( $OPTIND - 1 ))
fi

if ! which stow >/dev/null ; then
    log "ERROR: could not find 'stow' in your PATH"
    exit 1
fi

if [[ -z $skip_menu ]] && ! which whiptail >/dev/null ; then
    if ! which dialog >/dev/null ; then 
        log "ERROR: could not find 'whiptail' or 'dialog' in your PATH"
        exit 1
    fi
    alias whiptail=dialog
fi

####
## Walk the package tree

while IFS='' read -r -d $'\0'
    do found_packages+=("$REPLY")
done < <(find user system -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

want_packages=()
if [[ "$#" -gt 0 ]]; then
    want_packages=( "$@" )

elif [[ -s packages.txt ]]; then
    want_packages=( $(cat packages.txt) )

else
    # somewhat sensible defaults:
    # select all packages that end with our uname, 
    # and user packages that don't include the "_os" suffix
    for pkg in "${found_packages[@]}" ; do
        if [[ $pkg == *$(uname -s | tr A-Z a-z) ]] \
            || [[ $pkg == user/* && $pkg != *_* ]]
        then
            want_packages+=( "$pkg" )
        fi
    done
fi

if [[ -z $skip_menu ]]; then
    draw_menu
fi

if ! (( ${#want_packages[@]} )); then
    log "No packages selected, exiting."
    exit 0
fi

####
## Do the thing

log "Saved package list to packages.txt"
printf '%s\n' "${want_packages[@]}" | sort | tee packages.txt | perl -pe 's,^,\t - ,' >&2
read -p '[press enter to install now]'

declare target sudo type
for dir in "${want_packages[@]}"; do
    type="${dir%/*}"
    pkg="${dir#*/}"
    target="$HOME"
    sudo=""

    if [[ "$type" == system ]]; then
        if ! sudo -p "[sudo: install system packages] password for %p:" -v ; then
            log "system installation cancelled."
            exit
        fi
        target=/
        sudo=sudo
    fi

    log "Installing $type package '$pkg' ... "
    ( cd $type && install "$pkg" "$target" "$sudo" "$dry_run" )
done

log "Done."
