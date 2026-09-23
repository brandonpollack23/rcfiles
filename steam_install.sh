#!/bin/sh
#deleteme
while read -r appid; do
  steam "steam://install/$appid"
done <steam-appids.txt
