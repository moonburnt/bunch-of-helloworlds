## Smol bash script to download and update citra-nightly to latest version on linux
## Can probably be patched to work on any os supported by citra, but I cant test it outside of linux, so I didnt bother

#Now checks dependencies
#Now extraction process is silent
#Redesigned handling of citra.version
#Replaced "gio trash" with "rm -r"

#todo: add ability to set custom destination directory via launch argument

# Link to citra's latest release redirect
latest="https://github.com/citra-emu/citra-nightly/releases/latest"
# Script's cache directory
cache="$HOME/.cache/citrabump/"
# Script's destination directory. Temporary, will replace with argument or something
citradir="$HOME/.citra/"
# Script's version file
citraversion="citra.version"

# Checking if we have all the required things installed
dependency_check() {
    if ! command -v $1 &>/dev/null; then
        echo "Couldnt find $1. Please install it and try again"
        exit 2
    fi
}

dependency_check 7z
dependency_check wget
dependency_check grep
dependency_check head

echo "Fetching latest release from citra's github page"
release="$(wget -qO- "$latest" | grep -o '/citra-emu/citra-nightly/releases/download/nightly[^"]*linux[^"]*.7z' | sort -u)"

# Getting the name of release - without link itself, nor filename extension
versionname="${release##*/}"
versionname="${versionname%.*}"
echo "Latest available release is $versionname"

## Getting name of installed version of citra.
installedversion="$(head -n 1 "$citradir/$citraversion" 2>/dev/null)"

# Comparing installed version with whatever available.
# If these dont match or file didnt exist (in that case $installedversion will be empty) - download new one
if [[ "$versionname" == "$installedversion" ]]; then
    echo "You already have latest version available. Nothing to do here"
else
    echo "Downloading latest version locally"

    if [ -e "$cache" ]; then
        rm -r "$cache" || exit 1 #removing already existing cache directory, to avoid old files
    fi
    mkdir -p "$cache" || exit 1
    wget -q -P "$cache" "https://github.com/$release" || exit 1

    echo "Extracting into cache directory"
    cd "$cache"
    7z x "$versionname.7z" >/dev/null || exit 1 #this will always extract into $cache/nightly

    # Writing current version's name into file. If existed - overwriting old variable
    echo "$versionname" > "./nightly/$citraversion"

    echo "Moving data into citra directory"

    mkdir -p "$citradir" || exit 1
    cp -a ./nightly/* "$citradir" || exit 1

    echo "Cleaning up the cache"
    rm -r "$cache" || exit 1
fi

echo "Done"
exit 0
