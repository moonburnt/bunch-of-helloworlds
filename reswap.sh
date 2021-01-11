#!/bin/bash
##Script that restarts swap

#Checking if launched as root
if [ "$(id -u)" != 0 ]; then
    echo "This script needs to be launched as root"
    exit 2
fi

echo "Restarting the swaps..."

#Restarting the swaps
swapoff -a && swapon -a && echo "Successfully restarted all swaps!" && exit 0
