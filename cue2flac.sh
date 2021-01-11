#!/bin/bash

# Simple bash script to split music album's images into separate flac files

#now looping confirmation until selected valid input
#now fixing cue encoding for non-utf-8/ascii files (limited by list of languages known to enca)

#todo: ability to manually select out of multiple cues and multiple flacs
#todo: show help on empty input
#todo: ability to split non-flac images

tempcue="temp.cue"

# First of all - lets check for dependencies
dependency_check() {
    if ! command -v $1 &>/dev/null; then
        echo "Couldnt find $1. Please install it and try again"
        exit 2
    fi
}

dependency_check sed
dependency_check grep
dependency_check enca
dependency_check iconv
dependency_check shnsplit

# Now lets find out if our current directory has cue and flac files in it
cuefile="$(find *.cue -type f -print | head -n 1)"
echo "$cuefile" | grep -q "." || exit 1

flacfile="$(find *.flac -type f -print | head -n 1)"
echo "$flacfile" | grep -q "." || exit 1

printf "Cuesheet is $cuefile and music file is $flacfile\nProceed? [Y/N]\n"
while true; do
    read -p "" confirmation
    case "$confirmation" in
        (y|Y) break ;;
        (n|N) echo "Abort" && exit 1;;
    esac
done

# Checking cue file's encoding, to then fix it if its not UTF-8 or ASCII, as others tend to produce unreadable characters on modern systems
# At first - lets get array out of known enca languages
encalangs=()
while IFS= read -r line; do
    langname="${line%%:*}"
    encalangs+=($langname)
done < <(enca --list=languages)

# Now lets try to find if our cue file match any of these
for item in "${encalangs[@]}"; do
    if [[ "$?" == 0 ]]; then
        cuelang="$item"
        break
    fi
done

cuencoding="$(enca -L "$cuelang" -i "$cuefile" 2>/dev/null)" #this will break if file is in some weird encoding, unsupported by enca. Mybe will fix later

if [ "$cuencoding" != "UTF-8" ] && [ "$cuencoding" != "ASCII" ]; then
    echo "Encoding of $cuefile is $cuencoding. Attempting to fix"
    iconv -f "$cuencoding" -t utf-8 "$cuefile" > "$tempcue" || exit 1
    echo "Successfully fixed cuefile's encoding"
    cuefile="$tempcue" #we are using temporary cuefile to avoid overwriting already existing one
else
    echo "Encoding of $cuefile is $cuencoding, no need to fix it"
fi

echo "Determining output directory's name based on cue data"
#exit 0
albumdir="$(cat "$cuefile" | grep TITLE | head -n 1 | sed -s 's/TITLE //' | sed -e 's/"\(.*\)"/\1/' | sed 's/.$//')"

echo "Setting output directory to $albumdir"
mkdir -p "./$albumdir"

echo "Splitting music image into flac tracks"
shnsplit -f "$cuefile" -o flac -t "%n. %t" "$flacfile" -d "./$albumdir"

echo "Tagging music tracks"
cp "$cuefile" "./$albumdir/$cuefile"
cd "./$albumdir"
cuetag.sh "$cuefile" *.flac

echo "Done"
