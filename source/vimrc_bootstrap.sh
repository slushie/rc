#!/usr/bin/env bash

if [[ ! -d ~/.vim/bundle/vundle ]]; then
    git clone -b 0.9.1 https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/vundle
fi
