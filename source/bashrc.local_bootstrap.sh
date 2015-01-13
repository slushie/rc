#!/usr/bin/env bash

if [ -e ~/.bashrc ] && grep -vq '.bashrc.local' ~/.bashrc ; then
    echo "Sourcing \`.bashrc.local\` from within ~/.bashrc"

    echo -e "\n# Source local bashrc"        >> ~/.bashrc
    echo 'if [[ -r ~/.bashrc.local ]]; then' >> ~/.bashrc
    echo '  source ~/.bashrc.local'          >> ~/.bashrc
    echo 'fi'                                >> ~/.bashrc
fi
