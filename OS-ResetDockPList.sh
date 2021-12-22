#!/bin/sh

currentuser=`stat -f "%Su" /dev/console`

su "$currentuser" -c "defaults delete com.apple.dock"
sleep 1
killall Dock
sleep 4
