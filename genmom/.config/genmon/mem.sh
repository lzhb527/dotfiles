#!/bin/bash

# xfce4-genmon script to monitor current memory usage
# 2020 (ɔ) almaceleste
ICON_PATH="/home/lee/.config/genmon/memory.png"
# mem usage threshold warning (in GB) - yellow
warn=2
# mem usage threshold alarm (in GB) - red
alarm=1

#used=$(free --giga | sed -n '2p' | awk '{printf "%d", $3}')
used=$(free -m | sed -n '2p' | awk '{if ($3 < 1024) printf "%dM", $3; else printf "%.1fG", $3/1024}')
free=$(free --human --giga | sed -n '2p' | awk '{printf "%s", $4}')
shared=$(free --human --giga | sed -n '2p' | awk '{printf "%s", $5}')
avail=$(free --human --giga | sed -n '2p' | awk '{printf "%s", $7}')

color='lightgrey'
if [ $used -gt $alarm ]
then
    color='red'
elif [ $used -gt $warn ]
then
    color='yellow'
fi
used="${used}"

echo "<img>${ICON_PATH}</img><txt><span foreground="\'$color\'">$used</span></txt>"
echo -e "<tool>mem: \t$used used\n\t\t$free free\n\t\t$shared shared\n\t\t$avail avail</tool>"
