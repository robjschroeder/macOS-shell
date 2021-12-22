#!/bin/sh
#
#
# Name: Applications-Adobe-RemoteUpdateManager-Run.sh
#
# Purpose: This script uses jamfhelper to show which updates are available for Adobe CC and asks
# if they would like to install those updates.  If they choose to install updates it will begin installing updates.
#

icons=/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources
rumlog=/var/tmp/RUMupdate.log # mmmmmm, rum log
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
oldRUM=/usr/sbin/RemoteUpdateManager # this is where RUM used to live pre-10.11
rum=/usr/local/bin/RemoteUpdateManager # post-10.11
jamf_bin=/usr/local/bin/jamf

# Installer function
installUpdates ()
{
    # Let's caffinate the mac because this can take long
    caffeinate -d -i -m -u &
    caffeinatepid=$!

    # Displaying jamfHelper
    "$jamfHelper" -windowType hud -title " Adobe Updater" -description "Downloading and Installing Updates, this may take some time..." \
    -icon "$icons/Sync.icns" -lockHUD > /dev/null 2>&1 &

    # do all of your work here
    $rum --action=install

    # Kill jamfhelper
    killall jamfHelper > /dev/null 2>&1

    # No more caffeine please. I've a headache.
    kill "$caffeinatepid"

    exit 0
}


#############
#  Script   #
#############


# old RUM installed?
if [ -f $oldRUM ] ; then
    rm -rf $oldRUM
fi

# new/current RUM installed?
if [ ! -f $rum ] ; then
	echo "Installing RUM from JSS"
	$jamf_bin policy -event installRUM
	if [ ! -f $rum ] ; then
		echo "Couldn't install RUM! Exiting."
		exit 1
	fi
fi

# Not that it matters but we'll remove the old log file if it exists
if [ -f $rumlog ] ; then
    rm $rumlog
fi

#run RUM and output to the log file
touch $rumlog
$rum --action=list > $rumlog

# super-echo!  Echo pretty-ish output to user. Replaces Adobes channel IDs with actual app names
# I think it's silly that I have to do this, but whatever. :)
# Adobe channel ID list: https://helpx.adobe.com/enterprise/package/help/apps-deployed-without-their-base-versions.html
secho=`sed -n '/Following*/,/\*/p' $rumlog \
    | sed 's/Following/The\ Following/g' \
    | sed 's/ACR/Acrobat/g' \
    | sed 's/AEFT/After\ Effects/g' \
    | sed 's/AME/Media\ Encoder/g' \
    | sed 's/AUDT/Audition/g' \
    | sed 's/FLPR/Animate/g' \
    | sed 's/ILST/Illustrator/g' \
    | sed 's/MUSE/Muse/g' \
    | sed 's/PHSP/Photoshop/g' \
    | sed 's/PRLD/Prelude/g' \
    | sed 's/SPRK/XD/g' \
    | sed 's/KBRG/Bridge/g' \
    | sed 's/AICY/InCopy/g' \
    | sed 's/ANMLBETA/Character\ Animator\ Beta/g' \
    | sed 's/DRWV/Dreamweaver/g' \
    | sed 's/IDSN/InDesign/g' \
    | sed 's/PPRO/Premiere\ Pro/g' \
    | sed 's/LTRM/Lightroom\ Classic/g' \
    | sed 's/CHAR/Character\ Animator/g' \
    | sed 's/ESHR/Dimension/g' `

if [ "$(grep "Following Updates are applicable" $rumlog)" ] ; then
  userChoice=$("$jamfHelper" -windowType hud -lockHUD -title " Adobe Updater" \
  -icon "$icons/ToolbarInfo.icns" -description "Do you want to install these updates?
$secho" -button1 "Yes" -button2 "No")
    if [ "$userChoice" == "0" ]; then
        echo "User said yes, installing $secho"
        installUpdates
    elif [ "$userChoice" == "2" ]; then
        echo "User said no"
        exit 0
    fi
else
    "$jamfHelper" -windowType hud -title " Adobe Updater" -description "There are no Adobe Updates available." \
    -icon "$icons/ToolbarInfo.icns" -button1 Ok -defaultButton 1
    exit 0
fi
