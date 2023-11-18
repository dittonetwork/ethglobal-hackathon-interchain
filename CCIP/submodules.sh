#!/bin/sh

set -e

git config -f .gitmodules --get-regexp '^submodule\..*\.path$' |
    while read path_key path
    do
        name=$(echo $path_key | sed 's/submodule\.//;s/\.path//')
        url_key=$(echo $path_key | sed 's/\.path/.url/')
        branch_key=$(echo $path_key | sed 's/\.path/.branch/')
        url=$(git config -f .gitmodules --get "$url_key")
        branch=$(git config -f .gitmodules --get "$branch_key" || echo "master")
        git submodule add -f -b $branch --name $name $url $path || continue
        git submodule update --init --recursive --remote $local_path
    done