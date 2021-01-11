#!/bin/bash

## Smol bash script to batch-update python packages, installed with pip into --user
## Can be used as part of bigger autoupdate script or thrown into cron
## WARNING: doesnt upgrade packages from previous python versions - you still need to re-install them manually... yet

dependency_check() {
    if ! command -v $1 &>/dev/null; then
        printf "Couldnt find $1. Please install it and try again\n"
        exit 2
    fi
}

dependency_check pip
dependency_check jq

#getting list of outdated packages
printf "Getting the list of packages...\n"
outdated_pkgs=($(pip list --outdated --user --format json | jq -r ".[] | .name"))

if [ -z "${outdated_pkgs[@]}" ]; then
    printf "All locally installed pip packages are up to date!\n"
else
    printf "The following packages are out of date and will be upgraded:\n${outdated_pkgs[@]}\n"

    for item in "${outdated_pkgs[@]}"; do
        pip install --user --upgrade "$item"
    done
fi

printf "Done\n"
