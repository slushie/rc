#!/usr/bin/env bash
# install all my dotfiles

dotfiles=$(cat dotfiles.txt)

for file in $dotfiles; do
    source_path="${PWD}/source/$file"
    bootstrap_script="${source_path}_bootstrap.sh"
    destination="${HOME}/.${file}"

    if [ -e $bootstrap_script ]; then
        source $bootstrap_script
    fi

    if [ -e $destination ]; then
        echo "Making backup of existing $file"
        mv -iv $destination $destination.backup
    fi
    
    ln -sfv $destination $source
done
