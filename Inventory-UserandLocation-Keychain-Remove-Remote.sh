#!/bin/bash

# This script will remove the contents
# of the user's (defined by $4) keychain 
# to be to be rebuilt upon next login.
#
# Updated: 2.23.2022 @ Robjschroeder
#
# $4 passed from Jamf Pro policy
user=$4
# Remove the contents of the keychain
rm -f -r "/Users/$user/Library/Keychains/"*
# Reboot the computer in 1 minute
shutdown -r +1
exit
