#!/bin/sh
#
#
#     Created by A.Hodgson
#      Date: 03/01/2019
#      Purpose: Unsign Configuration profile
#  
#
######################################

#user
loggedInUser=$(/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }')

#profileLocation
read -p "Please drag your signed profile into terminal: " signedProfile

output=$(security cms -D -i "$signedProfile" | xmllint --format - > "/Users/$loggedInUser/Downloads/unsignedProfile.mobileconfig")

if [$output == ""]
then
	echo ""
	echo "Profile has been unsigned and output to /Users/$loggedInUser/Downloads/unsignedProfile.mobileconfig"
	#exit script gracefully
	exit 0 
else 
	echo ""
	echo "Something went wrong:"
	echo $output
	#remove bogus file
	[ -e /Users/$loggedInUser/Downloads/unsignedProfile.mobileconfig ] && rm -f /Users/$loggedInUser/Downloads/unsignedProfile.mobileconfig
	#exit script error
	exit 1 
fi