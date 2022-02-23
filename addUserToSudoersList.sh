#!/bin/bash
#
# This script will add the logged in
# user to the sudoers list.
# Can be ran from Jamf Pro via Policy
#
# Updated: 2.23.2022 @ Robjschroeder
#
# Get the logged in user
loggedInUser=$( /usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ {print$3}' )

# Verify string exists in sudoers
file="/etc/sudoers"
string="#includedir /private/etc/sudoers.d"
file_content=$( cat "${file}" )
if [[ " $file_content " =~ $string ]]; then
	echo "String is found, continuing..."
else
	echo "#includedir /private/etc/sudoers.d not found, adding string now..."
	echo "#includedir /private/etc/sudoers.d" >> /etc/sudoers
fi

# Check for sudoers file
if [ -f "/etc/sudoers.d/sudoers" ]; then
	echo "Sudoers file exists, adding user..."
	echo "${loggedInUser} ALL=(ALL) ALL" >> /etc/sudoers.d/sudoers
else
	echo "Creating sudoers file and adding user..."
	touch /etc/sudoers.d/sudoers
	echo "${loggedInUser} ALL=(ALL) ALL" >> /etc/sudoers.d/sudoers
fi

exit 0
