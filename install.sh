#!/bin/bash
# this is the main installation script

install () {
    pkg="$1"
    target="$2"
    bin="$3"

    [[ -d "$pkg" ]] || return 1
    if [[ -x "$pkg.preinstall" ]]; then
        ./$pkg.preinstall "$target" || return 2
    fi
    $bin stow $STOW_OPTS -S --no-folding -t "$target" "$pkg"
    if [[ -x "$pkg.postinstall" ]]; then
        ./$pkg.postinstall "$target" && return 0
        echo 1>&2 "ERROR: $pkg postinstall failed, rolling back."
        $bin stow $STOW_OPTS -D --no-folding -t "$target" "$pkg"
        return 2
    fi
    return 0
}

platform=$(uname | tr A-Z a-z)
packages=(dotfiles dotfiles-$platform)
system_packages=($platform)



echo 1>&2 "NOTE: installing user packages to HOME=$HOME"
echo -n "[${packages[*]}] press enter:"
read

# user-local packages
for pkg in ${packages[@]}; do
    echo 1>&2 "Installing '$pkg'... "
    if ! install "$pkg" "$HOME"; then
        err=$?
        echo 1>&2 "Package $pkg had error: ERR$err"
    else
        echo 1>&2 "Package $pkg installed OK"
    fi
done

echo 1>&2 "NOTE: installing system packages to root directory"
if ! sudo -p "[sudo: ${system_packages[*]}] password for %p:" -v ; then
    echo 1>&2 "system installation cancelled."
    exit
fi

for pkg in ${system_packages[@]}; do
    echo 1>&2 "Installing '$pkg'... "
    if ! install "$pkg" "/" sudo; then
        err=$?
        echo 1>&2 "Package $pkg had error: ERR$err"
    else
        echo 1>&2 "Package $pkg installed OK"
    fi
done

echo 1>&2 "Done."
