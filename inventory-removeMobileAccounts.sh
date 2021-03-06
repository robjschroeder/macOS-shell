#!/bin/bash

# Identifies mobile accounts on macOS
# then deletes them securely, unless the
# currently logged in user is a mobile user, 
# then the script will skip deleting that user.
#
# Updated: 4.22.2022 @ Robjschroeder 

# Get the currently logged in user, if any
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

# Get list of mobile accounts on computer, then delete if they are not currently logged in
mobileAccountList=$( dscl . list /Users OriginalNodeName | awk '{print $1}' 2>/dev/null)
if [  "${mobileAccountList}" == "" ]; then
	echo "No Mobile Accounts"
else
	echo "Deleting ${mobileAccountList}"
	for user in ${mobileAccountList}; do
    	if [ "${user}" == ${loggedInUser} ]; then
        echo "Mobile user currently logged in, skipping ${user}"
        else
		sysadminctl -deleteUser ${user} -secure
        fi
	done
fi

exit 0
