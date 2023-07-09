#!/bin/bash
# finds vendored go packages under the current directory
# and outputs only the top-level package path names

if [[ ! -d vendor ]]; then
    echo "ERROR: no 'vendor' directory found under $PWD" 1>&2
    exit 1
fi

find ./vendor -type f -name \*.go | 
    xargs dirname | 
    sort -u | 
    perl -laE 'while(<ARGV>){chomp;say $r=$_ unless $r&&/^$r/}'
