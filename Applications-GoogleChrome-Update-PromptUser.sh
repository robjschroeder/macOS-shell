#!/bin/bash

# Check we have the timer file and if not create it and populate with 5
# which represents the number of defers the end user will have

if [ ! -e /Library/Application\ Support/JAMF/.ChromeUpgradeTimer.txt ]; then
    echo "5" > /Library/Application\ Support/JAMF/.ChromeUpgradeTimer.txt
fi

########################################################################
#################### Variables to be used by the script ################
########################################################################

# # # # # # # # # # # # # # # #
#Custom Trigger for Chrome Update
#jssChromeTrigger="chromeInstall2"
# # # # # # # # # # # # # # # #

#Get the logged in LoggedInUser
LoggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`
echo "Current LoggedInUser is $LoggedInUser"

#Get the value of the timer file and store for later
Timer=$(cat /Library/Application\ Support/JAMF/.ChromeUpgradeTimer.txt)

#Go get the Sierr icon from Apple's website
curl -s --url https://upload.wikimedia.org/wikipedia/commons/8/87/Google_Chrome_icon_%282011%29.png > /var/tmp/chrome.png

jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
icon="/var/tmp/chrome.png"
title="Message from  Service Desk"
heading="An important Google Chrome upgrade is availabe for your Mac - $Timer deferrals remaining"
description="The Google Chrome upgrade includes new features, security updates and performance enhancements.

Would you like to upgrade now? You may choose to not upgrade Google Chrome now, but after $Timer deferrals your mac will be automatically upgraded. Google Chrome must quit to complete the upgrade. If you do not choose to upgrade Chrome today, you will be reminded tomorrow."

########################################################################
#################### Functions to be used by the script ################
########################################################################

function jamfHelperAsktoUpgrade ()
{
  HELPER=` "$jamfHelper" -windowType utility -icon "$icon" -heading "$heading" -alignHeading center -title "$title" -description "$description" -button1 "Later" -button2 "Upgrade Now" -defaultButton "2" `
}

jamfHelperUpdateInProgress ()
{
#Show a message via Jamf Helper that the update has started - & at end so the script can carry on after jamf helper is launched.
su - $LoggedInUser <<'jamfmsg2'
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Library/Application\ Support/JAMF/bin/Management\ Action.app/Contents/Resources/Self\ Service.icns -title "Message from  Service Desk" -heading "Downloading Upgrade Package" -alignHeading center -description "Google Chrome upgrade including new features, security updates and performance enhancements has started.
Thank you &
jamfmsg2
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# START THE SCRIPT
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

#First up check is anyone is home, if not then just upgrade
if [ "$LoggedInUser" == "" ]; then
        echo "No one home, upgrade"
        /bin/echo "Update Google Chrome"
        rm -rf /Library/Application\ Support/JAMF/.ChromeUpgradeTimer.txt
        /bin/echo "Starting installation of Google Chrome"
        sleep 5
        killall "Google Chrome"
		sleep 10
		# Vendor supplied DMG file
		VendorDMG="googlechrome.dmg"

		# Download vendor supplied DMG file into /tmp/
		curl https://dl.google.com/chrome/mac/stable/GGRO/$VendorDMG -o /tmp/$VendorDMG

		# Mount vendor supplied DMG File
		hdiutil attach /tmp/$VendorDMG -nobrowse

		# Copy contents of vendor supplied DMG file to /Applications/
		# Preserve all file attributes and ACLs
		cp -pPR /Volumes/Google\ Chrome/Google\ Chrome.app /Applications/

		# Identify the correct mount point for the vendor supplied DMG file 
		GoogleChromeDMG="$(hdiutil info | grep "/Volumes/Google Chrome" | awk '{ print $1 }')"

		# Unmount the vendor supplied DMG file
		hdiutil detach $GoogleChromeDMG

		# Remove the downloaded vendor supplied DMG file
		rm -f /tmp/$VendorDMG
        exit 0
fi


# Check the value of the timer variable, if greater than 0 i.e. can defer
# then show a jamfHelper message
if [ $Timer -gt 0 ]; then
/bin/echo "User has "$Timer" deferrals left"
##Launch jamfHelper
/bin/echo "Launching jamfHelper..."
PROCESS_NAME=Google\ Chrome
if pgrep $PROCESS_NAME; then
    echo 'Google Chrome Running';
    jamfHelperAsktoUpgrade
#Get the value of the jamfHelper, user chosing to upgrade now or defer.
    if [ "$HELPER" == "0" ]; then
            #User chose to ignore
            echo "User clicked no"
            let CurrTimer=$Timer-1
            echo "$CurrTimer" > /Library/Application\ Support/JAMF/.ChromeUpgradeTimer.txt
            exit 0
    else
            #User clicked yes
            /bin/echo "User clicked yes"
            jamfHelperUpdateInProgress
            rm -rf /Library/Application\ Support/JAMF/.ChromeUpgradeTimer.txt
            /bin/echo "Starting installation of Google Chrome"
            sleep 5
            killall "Google Chrome"
		    sleep 10
		    # Vendor supplied DMG file
		    VendorDMG="googlechrome.dmg"

		    # Download vendor supplied DMG file into /tmp/
		    curl https://dl.google.com/chrome/mac/stable/GGRO/$VendorDMG -o /tmp/$VendorDMG

		    # Mount vendor supplied DMG File
		    hdiutil attach /tmp/$VendorDMG -nobrowse

		    # Copy contents of vendor supplied DMG file to /Applications/
		    # Preserve all file attributes and ACLs
		    cp -pPR /Volumes/Google\ Chrome/Google\ Chrome.app /Applications/

		    # Identify the correct mount point for the vendor supplied DMG file 
		    GoogleChromeDMG="$(hdiutil info | grep "/Volumes/Google Chrome" | awk '{ print $1 }')"

		    # Unmount the vendor supplied DMG file
		    hdiutil detach $GoogleChromeDMG

		    # Remove the downloaded vendor supplied DMG file
		    rm -f /tmp/$VendorDMG
		    sleep 10
            open -a Google\ Chrome
            "$jamfHelper" -windowType utility -icon "$icon" -heading "Update Complete" -alignHeading center -title "$title" -description "Google Chrome has been updated" -button1 "Ok"
            exit 0

        exit 1
        fi

    else
    echo "Google Chrome not running, proceeding with update"
    /bin/echo "Update Google Chrome"
    rm -rf /Library/Application\ Support/JAMF/.ChromeUpgradeTimer.txt
    /bin/echo "Starting installation of Google Chrome"
    sleep 5
    killall "Google Chrome"
	sleep 10
	# Vendor supplied DMG file
	VendorDMG="googlechrome.dmg"

	# Download vendor supplied DMG file into /tmp/
	curl https://dl.google.com/chrome/mac/stable/GGRO/$VendorDMG -o /tmp/$VendorDMG

	# Mount vendor supplied DMG File
	hdiutil attach /tmp/$VendorDMG -nobrowse

	# Copy contents of vendor supplied DMG file to /Applications/
	# Preserve all file attributes and ACLs
	cp -pPR /Volumes/Google\ Chrome/Google\ Chrome.app /Applications/

	# Identify the correct mount point for the vendor supplied DMG file 
	GoogleChromeDMG="$(hdiutil info | grep "/Volumes/Google Chrome" | awk '{ print $1 }')"

	# Unmount the vendor supplied DMG file
	hdiutil detach $GoogleChromeDMG

	# Remove the downloaded vendor supplied DMG file
	rm -f /tmp/$VendorDMG
fi

# Check the value of the timer variable, if equals 0 then no deferal left run the upgrade
else
if [ $Timer -eq 0 ]; then
  /bin/echo "No Defer left run the install"
    rm -rf /Library/Application\ Support/JAMF/.ChromeUpgradeTimer.txt
    /bin/echo "Starting installation of Google Chrome"
    	sleep 5
        killall "Google Chrome"
		sleep 10
		# Vendor supplied DMG file
		VendorDMG="googlechrome.dmg"

		# Download vendor supplied DMG file into /tmp/
		curl https://dl.google.com/chrome/mac/stable/GGRO/$VendorDMG -o /tmp/$VendorDMG

		# Mount vendor supplied DMG File
		hdiutil attach /tmp/$VendorDMG -nobrowse

		# Copy contents of vendor supplied DMG file to /Applications/
		# Preserve all file attributes and ACLs
		cp -pPR /Volumes/Google\ Chrome/Google\ Chrome.app /Applications/

		# Identify the correct mount point for the vendor supplied DMG file 
		GoogleChromeDMG="$(hdiutil info | grep "/Volumes/Google Chrome" | awk '{ print $1 }')"

		# Unmount the vendor supplied DMG file
		hdiutil detach $GoogleChromeDMG

		# Remove the downloaded vendor supplied DMG file
		rm -f /tmp/$VendorDMG
		sleep 10
		open -a Google\ Chrome
        "$jamfHelper" -windowType utility -icon "$icon" -heading "Update Complete" -alignHeading center -title "$title" -description "Google Chrome has been updated" -button1 "Ok"
    exit 0
  exit 1
  fi
fi
