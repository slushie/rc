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

declare dry_run=
if [[ $# -gt 0 ]]; then
    while getopts "hnv" arg; do
        case "$arg" in
            n) log "Dry run mode, commands printed but not run."; dry_run="log" ;;
            v) set -x ;; 
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

if ! which whiptail >/dev/null ; then
    if ! which dialog >/dev/null ; then 
        log "ERROR: could not find 'whiptail' or 'dialog' in your PATH"
        exit 1
    fi
    alias whiptail=dialog
fi

declare -a found_packages want_packages
while IFS='' read -r -d $'\0'
    do found_packages+=("$REPLY")
done < <(find user system -mindepth 1 -maxdepth 1 -type d -print0 | sort)

want_packages=( "${found_packages[@]}" )
if [[ "$#" -gt 0 ]]; then
    want_packages=( "$@" )
elif [[ -s packages.txt ]]; then
    want_packages=( $(cat packages.txt) )
fi

declare -a menu_options menu_packages
declare status title index=0 menu_output=`mktemp`
trap "rm -f '$menu_output'" EXIT

for pkg in "${found_packages[@]}"; do
    ( printf '%s\0' "${want_packages[@]}" | grep -Fxzq -- "$pkg" ) \
        && status="on" || status="off"
    
    title="$(cut -d/ -f2 <<< "$pkg")"
    [[ "$pkg" == system/* ]] \
        && title="System package '$title' (requires sudo)" \
        || title="User package '$title'"

    index=$(( $index + 1 ))
    menu_options+=( "$index." "$title" $status )
done

: ${COLUMNS:=80}
: ${LINES:=22}
whiptail --separate-output --title 'Install Packages' \
    --checklist "Available Packages" $(( $LINES - 5 )) $(( $COLUMNS - 5 )) $(( $LINES - 10 )) \
    "${menu_options[@]}" \
    2>$menu_output >/dev/tty 
if [[ ! -s "$menu_output" ]]; then
    log "No packages selected, exiting."
    exit 0
fi

for tag in $(cat "$menu_output"); do
    index=$(( ${tag%.} - 1 ))
    menu_packages+=( "${found_packages[$index]}" )
done

log "Installing packages:"
printf '%s\n' "${menu_packages[@]}" | sort | tee packages.txt | perl -pe 's,^,\t - ,' >&2
read -p '[press enter to continue]'

declare target sudo type
for dir in "${menu_packages[@]}"; do
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
