#!/bin/bash

user_entry=""

validateResponce() {
    case "$user_entry" in
        "noinput" ) echo "empty input" & askInput ;;
        "cancelled" ) echo "time out/cancelled" & exit 1 ;;
        * ) echo "$user_entry"  ;;
    esac
}

askInput() {
user_entry=$(osascript <<EOF
use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
set theTextReturned to "nil"
tell application "System Events"
activate
try
set theResponse to display dialog "Enter the new name of your computer" with title "Rename Computer" default answer ""
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

/usr/sbin/scutil --set LocalHostName $user_entry
/usr/sbin/scutil --set HostName $user_entry
/usr/sbin/scutil --set ComputerName $user_entry
/usr/sbin/diskutil rename / $user_entry
/usr/local/bin/jamf setComputerName -name $user_entry

exit 0


done