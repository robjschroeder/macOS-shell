#!/bin/bash


# Intial setup script for macOS 10.13.x
# Last modified 10-17-2017
# Robert Schroeder
#   -Added DSDontWrite command
#   - Added SetupAssistant.plist commands for 10.13
#
# Initial setup script for macOS 10.12.x
# Rich Trouton, created June 22, 2016
# Last modified 9-16-2016
#
# Adapted from Initial setup script for Mac OS X 10.11.x
# Rich Trouton, created July 29, 2015
# Last modified 1-21-2016
# 
#
LOGPATH='/private/var/log'
JSSURL='https://tenant.jamfcloud.com'
JSSCONTACTTIMEOUT=120
FIRSTRUN='/Library/Application\ Support/JAMF/FirstRun/Enroll/enroll.sh'
ENROLLLAUNCHDAEMON='/Library/LaunchDaemons/com.jamfsoftware.firstrun.enroll.plist'
LOGFILE=/private/var/log/deployment-$(date +%Y%m%d-%H%M).logging

# Used to get model name of machine
lastCharsInSerialNum=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}' | cut -c 9-)
modelName=$(curl -s http://support-sp.apple.com/sp/product?cc="$lastCharsInSerialNum" | awk -F'<configCode>' '{print $2}' | awk -F'</configCode>' '{print $1}')
model=`sysctl -n hw.model`

## Setup logging
# mkdir $LOGPATH
set -xv; exec 1> $LOGPATH/postimagelog.txt 2>&1
#/usr/bin/say "Begining Post Image Script"

######################################################################################
# Dummy package with image date and computer Model
######################################################################################
/bin/echo "Creating imaging receipt..."
/bin/date
TODAY=`date +"%Y-%m-%d"`
touch /Library/Application\ Support/JAMF/Receipts/'!'$model.txt
echo 'This' $modelName 'was imaged on' $TODAY'.' >> /Library/Application\ Support/JAMF/Receipts/'!'$model.txt
echo 'This' $modelName 'was imaged on' $TODAY'.' >> /Library/Application\ Support/JAMF/Receipts/$TODAY.txt

/bin/echo "Setting system preferences"
/bin/date

# Sleeping for 30 seconds to allow the new default User Template folder to be moved into place

/bin/sleep 30
# now Activate Remote Desktop Sharing, enable access privileges for the users, grant full privileges for the users, restart arduser Agent and Menu extra:
rm /Library/Preferences/com.apple.ARDAgent.plist
rm /Library/Preferences/com.apple.RemoteManagement.plist
/bin/sleep 10
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -users admin -privs -all -restart -agent -menu
#/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -users Administrators -privs -all -restart -agent -menu

# Disable Time Machine's pop-up message whenever an external drive is plugged in

/usr/bin/defaults write /Library/Preferences/com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Disable root login by setting root's shell to /usr/bin/false
# Note: Setting this value has been known to cause issues seen
# by others when they used Casper's FileVault 2 management.
# If you are running Casper and see problems encrypting, the
# original UserShell value is as follows:
#
# /bin/sh
#
# To revert it back to /bin/sh, run the following command:
# /usr/bin/dscl . -change /Users/root UserShell /usr/bin/false /bin/sh

# /usr/bin/dscl . -create /Users/root UserShell /usr/bin/false

## Show on desktop

/bin/echo "Show on desktop"
/bin/date
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true

# Make a symbolic link from /System/Library/CoreServices/Applications/Directory Utility.app 
# to /Applications/Utilities so that Directory Utility.app is easier to access.

if [[ ! -e "/Applications/Utilities/Directory Utility.app" ]]; then
   /bin/ln -s "/System/Library/CoreServices/Applications/Directory Utility.app" "/Applications/Utilities/Directory Utility.app"
fi

if [[ -L "/Applications/Utilities/Directory Utility.app" ]]; then
   /bin/rm "/Applications/Utilities/Directory Utility.app"
   /bin/ln -s "/System/Library/CoreServices/Applications/Directory Utility.app" "/Applications/Utilities/Directory Utility.app"
fi

# Make a symbolic link from /System/Library/CoreServices/Applications/Network Utility.app 
# to /Applications/Utilities so that Network Utility.app is easier to access.

if [[ ! -e "/Applications/Utilities/Network Utility.app" ]]; then
   /bin/ln -s "/System/Library/CoreServices/Applications/Network Utility.app" "/Applications/Utilities/Network Utility.app"
fi

if [[ -L "/Applications/Utilities/Network Utility.app" ]]; then
   /bin/rm "/Applications/Utilities/Network Utility.app"
   /bin/ln -s "/System/Library/CoreServices/Applications/Network Utility.app" "/Applications/Utilities/Network Utility.app"
fi

# Make a symbolic link from /System/Library/CoreServices/Screen Sharing.app 
# to /Applications/Utilities so that Screen Sharing.app is easier to access.

if [[ ! -e "/Applications/Utilities/Screen Sharing.app" ]]; then
   /bin/ln -s "/System/Library/CoreServices/Applications/Screen Sharing.app" "/Applications/Utilities/Screen Sharing.app"
fi

if [[ -L "/Applications/Utilities/Screen Sharing.app" ]]; then
   /bin/rm "/Applications/Utilities/Screen Sharing.app"
   /bin/ln -s "/System/Library/CoreServices/Applications/Screen Sharing.app" "/Applications/Utilities/Screen Sharing.app"
fi

# Set separate power management settings for desktops and laptops
# If it's a laptop, the power management settings for "Battery" are set to have the computer sleep in 15 minutes, disk will spin down 
# in 10 minutes, the display will sleep in 5 minutes and the display itslef will dim to half-brightness before sleeping. While plugged 
# into the AC adapter, the power management settings for "Charger" are set to have the computer never sleep, the disk doesn't spin down, 
# the display sleeps after 30 minutes and the display dims before sleeping.
# 
# If it's not a laptop (i.e. a desktop), the power management settings are set to have the computer never sleep, the disk doesn't spin down, the display 
# sleeps after 30 minutes and the display dims before sleeping.
#

##########################################
# Power Management
##########################################
/bin/echo "Setting power management"
/bin/date
# Detects if this Mac is a laptop or not by checking the model ID for the word "Book" in the name.
IS_LAPTOP=`/usr/sbin/system_profiler SPHardwareDataType | grep "Model Identifier" | grep "Book"`

if [ "$IS_LAPTOP" != "" ]; then
    /usr/bin/pmset -b sleep 15 disksleep 10 displaysleep 5 halfdim 1
    /usr/bin/pmset -c sleep 0 disksleep 0 displaysleep 30 halfdim 1
else    
    /usr/bin/pmset sleep 0 disksleep 0 displaysleep 30 halfdim 1
fi

# Set the login window to name and password

/usr/bin/defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true

# Disable external accounts (i.e. accounts stored on drives other than the boot drive.)

/usr/bin/defaults write /Library/Preferences/com.apple.loginwindow EnableExternalAccounts -bool false

# Set the ability to  view additional system info at the Login window
# The following will be reported when you click on the time display 
# (click on the time again to proceed to the next item):
#
# Computer name
# Version of OS X installed
# IP address
# This will remain visible for 60 seconds.

## Changed to use config profile - line below for reference only...
#/usr/bin/defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Sets the "Show scroll bars" setting (in System Preferences: General)
# to "Always" in your Mac's default user template and for all existing users.
# Code adapted from DeployStudio's rc130 ds_finalize script, where it's 
# disabling the iCloud and gestures demos

# Checks the system default user template for the presence of 
# the Library/Preferences directory. If the directory is not found, 
# it is created and then the "Show scroll bars" setting (in System 
# Preferences: General) is set to "Always".

# Enable DSDontWrite - By default, the Finder collects labels, tags, and other metadata related to files on mounted SMB volumes before determining how 
# to display the files. macOS High Sierra 10.13 introduces the option for the Finder to fetch only the basic information about files on a mounted SMB 
# volume, and to display them immediately in alphabetical order. This can increase performance in certain environments.

/bin/echo "Enable DSDontWrite..."
/bin/date

for USER_TEMPLATE in "/System/Library/User Template"/*
  do
     if [ ! -d "${USER_TEMPLATE}"/Library/Preferences ]
      then
        /bin/mkdir -p "${USER_TEMPLATE}"/Library/Preferences
     fi
     if [ ! -d "${USER_TEMPLATE}"/Library/Preferences/ByHost ]
      then
        /bin/mkdir -p "${USER_TEMPLATE}"/Library/Preferences/ByHost
     fi
     if [ -d "${USER_TEMPLATE}"/Library/Preferences/ByHost ]
      then
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/.GlobalPreferences AppleShowScrollBars -string Always
        /usr/bin/defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE
     fi
  done

# Checks the existing user folders in /Users for the presence of
# the Library/Preferences directory. If the directory is not found, 
# it is created and then the "Show scroll bars" setting (in System 
# Preferences: General) is set to "Always".

for USER_HOME in /Users/*
  do
    USER_UID=`basename "${USER_HOME}"`
    if [ ! "${USER_UID}" = "Shared" ] 
     then 
      if [ ! -d "${USER_HOME}"/Library/Preferences ]
       then
        /bin/mkdir -p "${USER_HOME}"/Library/Preferences
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences
      fi
      if [ ! -d "${USER_HOME}"/Library/Preferences/ByHost ]
       then
        /bin/mkdir -p "${USER_HOME}"/Library/Preferences/ByHost
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences
    /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/ByHost
      fi
      if [ -d "${USER_HOME}"/Library/Preferences/ByHost ]
       then
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/.GlobalPreferences AppleShowScrollBars -string Always
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/.GlobalPreferences.*
        /usr/bin/defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE
      fi
    fi
  done


# Determine OS version and build version
# as part of the following actions to disable
# the iCloud and Diagnostic pop-up windows

osvers=$(sw_vers -productVersion | awk -F. '{print $2}')
sw_vers=$(sw_vers -productVersion)
sw_build=$(sw_vers -buildVersion)


# Checks first to see if the Mac is running 10.7.0 or higher. 
# If so, the script checks the system default user template
# for the presence of the Library/Preferences directory. Once
# found, the iCloud, Diagnostic and Siri pop-up settings are set 
# to be disabled.

if [[ ${osvers} -ge 7 ]]; then

 for USER_TEMPLATE in "/System/Library/User Template"/*
  do
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeCloudSetup -bool true
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant GestureMovieSeen none
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant LastSeenCloudProductVersion "${sw_vers}"
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant LastSeenBuddyBuildVersion "${sw_build}"
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeSiriSetup -bool TRUE 
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant.plist DidSeeSyncSetup -bool true
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant.plist DidSeeSyncSetup2 -bool true
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeApplePaySetup -bool false
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeAvatarSetup -bool false
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeCloudDiagnostics -bool false
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeTouchIDSetup -bool false
    /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeiCloudLoginForStorageServices -bool false

  done

 # Checks first to see if the Mac is running 10.7.0 or higher.
 # If so, the script checks the existing user folders in /Users
 # for the presence of the Library/Preferences directory.
 #
 # If the directory is not found, it is created and then the
 # iCloud, Diagnostic and Siri pop-up settings are set to be disabled.

 for USER_HOME in /Users/*
  do
    USER_UID=`basename "${USER_HOME}"`
    if [ ! "${USER_UID}" = "Shared" ] 
    then 
      if [ ! -d "${USER_HOME}"/Library/Preferences ]
      then
        /bin/mkdir -p "${USER_HOME}"/Library/Preferences
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences
      fi
      if [ -d "${USER_HOME}"/Library/Preferences ]
      then
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant DidSeeCloudSetup -bool true
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant GestureMovieSeen none
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant LastSeenCloudProductVersion "${sw_vers}"
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant LastSeenBuddyBuildVersion "${sw_build}"
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant DidSeeSiriSetup -bool TRUE
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant.plist DidSeeSyncSetup -bool true
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant.plist DidSeeSyncSetup2 -bool true
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant DidSeeApplePaySetup -bool false
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant DidSeeAvatarSetup -bool false
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant DidSeeCloudDiagnostics -bool false
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant DidSeeTouchIDSetup -bool false
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant DidSeeiCloudLoginForStorageServices -bool false
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant.plist
      fi
    fi
  done
fi

# disable automatic update downloads
defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool FALSE

# enable network time
systemsetup -setusingnetworktime on

# set the time server

systemsetup -setnetworktimeserver 1ntp.fq.dn,2ntp.fq.dn,time.apple.com

# Set whether you want to send diagnostic info back to
# Apple and/or third party app developers. If you want
# to send diagonostic data to Apple, set the following 
# value for the SUBMIT_DIAGNOSTIC_DATA_TO_APPLE value:
#
# SUBMIT_DIAGNOSTIC_DATA_TO_APPLE=TRUE
# 
# If you want to send data to third party app developers,
# set the following value for the
# SUBMIT_DIAGNOSTIC_DATA_TO_APP_DEVELOPERS value:
#
# SUBMIT_DIAGNOSTIC_DATA_TO_APP_DEVELOPERS=TRUE
# 
# By default, the values in this script are set to 
# send no diagnostic data: 

SUBMIT_DIAGNOSTIC_DATA_TO_APPLE=FALSE
SUBMIT_DIAGNOSTIC_DATA_TO_APP_DEVELOPERS=FALSE

# To change this in your own script, comment out the FALSE
# lines and uncomment the TRUE lines as appropriate.

# Set the appropriate number value for AutoSubmitVersion
# and ThirdPartyDataSubmitVersion by the OS version. 
# For 10.10.x, the value will be 4. 
# For 10.11.x, the value will be 5.
# For 10.12.x, the value will be 5.


if [[ ${osvers} -eq 10 ]]; then
  VERSIONNUMBER=4
elif [[ ${osvers} -ge 11 ]]; then
  VERSIONNUMBER=5
fi


# Checks first to see if the Mac is running 10.10.0 or higher. 
# If so, the desired diagnostic submission settings are applied.

if [[ ${osvers} -ge 10 ]]; then

  CRASHREPORTER_SUPPORT="/Library/Application Support/CrashReporter"

  if [ ! -d "${CRASHREPORTER_SUPPORT}" ]; then
    /bin/mkdir "${CRASHREPORTER_SUPPORT}"
    /bin/chmod 775 "${CRASHREPORTER_SUPPORT}"
    /usr/sbin/chown root:admin "${CRASHREPORTER_SUPPORT}"
  fi

 /usr/bin/defaults write "$CRASHREPORTER_SUPPORT"/DiagnosticMessagesHistory AutoSubmit -boolean ${SUBMIT_DIAGNOSTIC_DATA_TO_APPLE}
 /usr/bin/defaults write "$CRASHREPORTER_SUPPORT"/DiagnosticMessagesHistory AutoSubmitVersion -int ${VERSIONNUMBER}
 /usr/bin/defaults write "$CRASHREPORTER_SUPPORT"/DiagnosticMessagesHistory ThirdPartyDataSubmit -boolean ${SUBMIT_DIAGNOSTIC_DATA_TO_APP_DEVELOPERS}
 /usr/bin/defaults write "$CRASHREPORTER_SUPPORT"/DiagnosticMessagesHistory ThirdPartyDataSubmitVersion -int ${VERSIONNUMBER}
 /bin/chmod a+r "$CRASHREPORTER_SUPPORT"/DiagnosticMessagesHistory.plist
 /usr/sbin/chown root:admin "$CRASHREPORTER_SUPPORT"/DiagnosticMessagesHistory.plist

fi

###########
# SSH
###########
# enable remote log in, ssh
/bin/echo "Setting ssh"
/bin/date
# /usr/sbin/dseditgroup -o edit -a admin -t user com.apple.access_ssh
/usr/sbin/systemsetup -setremotelogin on


###########
#  AFP
###########
# Turn off DS_Store file creation on network volumes
/bin/echo "Turn off DS_Store"
/bin/date
defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.desktopservices DSDontWriteNetworkStores -bool true

###  Expanded print dialog by default
# <http://hints.macworld.com/article.php?story=20071109163914940>
#
/bin/echo "Expanded print dialog by default"
/bin/date
# expand the print window
defaults write /Library/Preferences/.GlobalPreferences PMPrintingExpandedStateForPrint2 -bool TRUE
##Disable Fast User Switching
#/bin/echo "Disable Fast User Switching"
#/bin/date
#defaults write /Library/Preferences/.GlobalPreferences MultipleSessionEnabled -bool FALSE

# Enable Application Firewall
defaults write /Library/Preferences/com.apple.alf globalstate -int 1
defaults write /Library/Preferences/com.apple.alf loggingenabled -int 1
defaults write /Library/Preferences/com.apple.alf stealthenabled -int 0

# Terminal command-line access warning
rm -rf /etc/motd
/usr/bin/touch /etc/motd
/bin/chmod 644 /etc/motd
/bin/echo "" >> /etc/motd
/bin/echo "This Apple Workstation, including all related equipment belongs to Organization. Unauthorized access to this workstation is forbidden and will be prosecuted by law. By accessing this system, you agree that your actions may be monitored if unauthorized usage is suspected." >> /etc/motd
/bin/echo "" >> /etc/motd

# enable location services
/bin/launchctl unload /System/Library/LaunchDaemons/com.apple.locationd.plist
uuid=$(/usr/sbin/system_profiler SPHardwareDataType | grep "Hardware UUID" | cut -c22-57)
/usr/bin/defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd."$uuid" LocationServicesEnabled -int 1
/usr/bin/defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd.notbackedup."$uuid" LocationServicesEnabled -int 1
/usr/sbin/chown -R _locationd:_locationd /var/db/locationd
/bin/launchctl load /System/Library/LaunchDaemons/com.apple.locationd.plist

##########################################
# /etc/authorization changes
##########################################

security authorizationdb write system.preferences allow
security authorizationdb write system.preferences.datetime allow
security authorizationdb write system.preferences.printing allow
security authorizationdb write system.preferences.energysaver allow
security authorizationdb write system.preferences.network allow
security authorizationdb write system.services.systemconfiguration.network allow

## universal Access - enable access for assistive devices
## http://hints.macworld.com/article.php?story=20060203225241914
/bin/echo "Enable assistive devices"
/bin/date
/bin/echo -n 'a' | /usr/bin/sudo /usr/bin/tee /private/var/db/.AccessibilityAPIEnabled > /dev/null 2>&1 
/usr/bin/sudo /bin/chmod 444 /private/var/db/.AccessibilityAPIEnabled
# Turn off Gatekeeper

/usr/sbin/spctl --master-disable

# Disable Gatekeeper's auto-rearm. Otherwise Gatekeeper
# will reactivate every 30 days. When it reactivates, it
# will be be set to "Mac App Store and identified developers"

/usr/bin/defaults write /Library/Preferences/com.apple.security GKAutoRearm -bool false

# play chime when plugging in the power
defaults write com.apple.PowerChime ChimeOnAllHardware -bool true; open /System/Library/CoreServices/PowerChime.app &

# Set the RSA maximum key size to 32768 bits (32 kilobits) in
# /Library/Preferences/com.apple.security.plist to provide
# future-proofing against larger TLS certificate key sizes.
#
# For more information about this issue, please see the link below:
# http://blog.shiz.me/post/67305143330/8192-bit-rsa-keys-in-os-x

# /usr/bin/defaults write /Library/Preferences/com.apple.security RSAMaxKeySize -int 32768
defaults write /Library/Preferences/com.apple.NetworkAuthorization AllowUnknownServers -bool YES


# DISABLE NATURAL SCROLLING
defaults write /Library/Preferences/.GlobalPreferences com.apple.swipescrolldirection -bool false
defaults write /System/Library/User\ Template/Non_localized/Library/Preferences/.GlobalPreferences com.apple.swipescrolldirection -bool false

#/usr/bin/say "Finished Post Image Script"