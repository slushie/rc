#!/usr/bin/env bash
# install all my dotfiles

manifest=dotfiles.txt

if (( $# )); then
    dotfiles="$@"
    for file in $dotfiles; do
        if grep -vq $file "$manifest"; then
            echo "Adding $file to manifest file $manifest"
            echo $file >> $manifest
        fi
    done
else
    dotfiles=$(cat "$manifest")
fi


source_base="${PWD}/source"

make_backup () {
    file="$1"
    destination="$2"
    echo "Making backup of existing $file"
    mv -iv $destination $destination.backup
}

install_symlink () {
    src="$1"
    dst="$2"
    ln -sfv "$src" "$dst"
}

for file in $dotfiles; do
    source_path="${source_base}/$file"
    bootstrap_script="${source_path}_bootstrap.sh"
    destination="${HOME}/.${file}"

    # source a bootstrap file for configuration if available
    if [[ -f $bootstrap_script ]]; then
        source $bootstrap_script
    fi

    # if destination dotfile already exists
    if [[ -f $destination ]]; then
        # symlinks
        if [[ -h $destination ]]; then
            # check where the link points
            link_dest=$(readlink "$destination")

            # link points to some other file, make a backup
            if [[ $link_dest != $source_path ]]; then
                make_backup "$file" "$destination"

            # link points to our file, nothing more to do
            else
                continue
            fi
        else
            # normal files need normal backup
            make_backup "$file" "$destination"
        fi
    fi
    
    install_symlink "$source_path" "$destination"
done
