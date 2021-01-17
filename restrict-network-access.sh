#!/bin/bash

## Script that makes it possible to restrict network access to applications via iptables+group policies
## Should work on arch and its derivatives - have no idea about other distros

scriptname=$(basename "$0")

dependency_check() {
    if ! command -v $1 &>/dev/null; then
        echo "Couldnt find $1. Please install it and try again"
        exit 2
    fi
}
dependency_check grep

if [ "$(id -u)" != 0 ]; then
    echo "This script needs to be launched as root"
    exit 2
fi

[ -z "$1" ] && echo "Not enough arguments! Usage: $scriptname name-of-user name-of-restriction-group" && exit 1
[ -z "$2" ] && echo "Not enough arguments! Usage: $scriptname name-of-user name-of-restriction-group" && exit 1
username="$1"
groupname="$2"

printf "Affected user will be $username and name of network restriction group is $groupname\nProceed? [Y/N]\n"
while true; do
    read -p "" confirmation
    case "$confirmation" in
        (y|Y) break ;;
        (n|N) echo "Abort" && exit 1;;
    esac
done

echo "Trying to add group $groupname"
# "grep -w" will search for exact match - useful to avoid entries with similar names
grep -qw $groupname /etc/group && echo "$groupname already exists! Please pick another name and try again" && exit 1
groupadd $groupname || exit 1

echo "Adding $username to $groupname"
getent passwd | grep -qw $username || (echo "Couldnt find $username in list of existing users! Abort" && exit 1)
usermod -aG $groupname $username || exit 1

echo "Backing up current iptables settings as /etc/iptables/iptables.rules.old"
iptables-save -f /etc/iptables/iptables.rules.old || exit 1
echo "Applying new iptables rules"
iptables -I OUTPUT 1 -m owner --gid-owner $groupname -j DROP
echo "Saving updated iptables settings as /etc/iptables/iptables.rules"
iptables-save -f /etc/iptables/iptables.rules

echo "Successfully finished setting up everything!"
echo "In order to run some application without internet access, just type: sg $groupname name-of-your-application"
exit 0
