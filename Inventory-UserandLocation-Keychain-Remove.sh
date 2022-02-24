#!/bin/bash

# This script will remove the contents
# of the logged in user's keychain to be
# to be rebuilt upon next login.
#
# Updated: 2.23.2022 @ Robjschroeder
#
# Get the logged in user
loggedInUser=$( ls -l /dev/console | awk '{print $3}' )

# Remove the keychain contents of the user
rm -f -r "/Users/$loggedInUser/Library/Keychains/"*
# Restart the computer in one minute
shutdown -r +1

exit
