#!/bin/bash

user=$4

loggedInUser=$( ls -l /dev/console | awk '{print $3}' )

userName=$(ls -la /dev/console | cut -d " " -f 4)

user_entry=""

validateResponce() {
    case "$user_entry" in
        "noinput" ) echo "empty input" & askInput ;;
        "cancelled" ) echo "time out/cancelled" & exit 1 ;;
        * ) echo "$user_entry"  ;;
    esac
}

askInput() {
user_entry=$(sudo -u "$userName" osascript <<EOF
use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
set theTextReturned to "nil"
tell application "System Events"
activate
try
set theResponse to display dialog "Please enter your old username" with title "Moving Old Files..." default answer ""
set theTextReturned to the text returned of theResponse
end try
if theTextReturned is "nil" then
return "cancelled"
else if theTextReturned is "" then
return "noinput"
else
return theTextReturned
end if
end tell
EOF
)
validateResponce "$user_entry"
}

askInput "$userName"

mv /Users/$user_entry/Desktop/* /Users/$loggedInUser/Desktop/
mv /Users/$user_entry/Documents/* /Users/$loggedInUser/Documents/
mv /Users/$user_entry/Downloads/* /Users/$loggedInUser/Downloads/
mv /Users/$user_entry/Movies/* /Users/$loggedInUser/Movies/
mv /Users/$user_entry/Music/* /Users/$loggedInUser/Music/
mv /Users/$user_entry/Pictures/* /Users/$loggedInUser/Pictures/
mv /Users/$user_entry/Public/* /Users/$loggedInUser/Public/

exit 0

done