#!/bin/bash

## Small bash script that helps to skip boring and tedious parts of creating new
## python git projects. Creates virtual environment, empty README.md and LICENSE,
## then initializes git repo

scriptname=$(basename "$0")

dependency_check() {
    if ! command -v $1 &>/dev/null; then
        echo "Couldnt find $1. Please install it and try again"
        exit 2
    fi
}

dependency_check git
dependency_check virtualenv

if [ ! -z "$1" ]; then
    workdir="."
    #TODO: add ability to create directory
    cd "$1" || exit 2
fi

printf "Initializing repo in $PWD directory\n"
printf "Creating empty README.md and LICENSE files\n"
touch "README.md" || exit 2 #exiting in case we dont have write privilegies
touch "LICENSE"
printf "Initializing virtualenv\n"
virtualenv ".venv"
printf "Initializing git repository\n"
git init
printf "Done\n"
