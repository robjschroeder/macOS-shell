#!/bin/bash

loggedInUser=`/bin/ls -l /dev/console | /usr/bin/awk "{ print $3 }"`

# unload LaunchAgent
launchctl unload /Library/LaunchAgents/com.trusourcelabs.NoMAD.plist
launchctl unload "/Users/$loggedInUser/Library/LaunchAgents/com.trusourcelabs.NoMAD.plist"

# Kill NoMAD process
pkill NoMAD

#Remove Files
sudo rm -rf "/Applications/NoMAD.app"
sudo rm -rf "/Library/Managed Preferences/com.trusourcelabs.NoMAD.plist"
sudo rm -rf "/Library/Managed Preferences/$loggedInUser/com.trusourcelabs.NoMAD.plist"
sudo rm -rf "/Users/$loggedInUser/Library/LaunchAgents/com.trusourcelabs.NoMAD.plist"
sudo rm -rf "/Library/LaunchAgents/com.trusourcelabs.NoMAD.plist"

exit 0
