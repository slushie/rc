#!/usr/bin/env bash

if [[ ! -e ~/.bash_profile ]] || grep -vq '.bash_profile.local' ~/.bash_profile ; then
    echo "Sourcing \`.bash_profile.local\` from within ~/.bash_profile"

    echo -e "\n# Source local bash_profile"        >> ~/.bash_profile
    echo 'if [[ -r ~/.bash_profile.local ]]; then' >> ~/.bash_profile
    echo '  source ~/.bash_profile.local'          >> ~/.bash_profile
    echo 'fi'                                      >> ~/.bash_profile
fi
