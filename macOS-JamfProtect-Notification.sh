jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

#Header for Pop Up
heading="IT Security Notification" 

#Description for Pop Up
description="Malicious activity was recently captured from your Mac. Contact the Service Desk immediately. ServiceDesk@domain.com or PHONE"

#Button Text 
button1="Ok"

#Policy ID for policy in Self Service to Zip, Move, and Delete Malware caught by Threat Prevention
#policyID="64"

#Pixel Size for Pop Up
size=50

#Path for Icon Displayed
icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns"

userChoice=$("$jamfHelper" -windowType utility -iconSize "$size" -heading "$heading" -description "$description" -button1 "$button1" -icon "$icon")
	if [[ $userChoice == 0 ]]; then 
    	echo "user clicked $button1"
	fi