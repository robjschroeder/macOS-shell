#!/bin/bash

##Heading to be used for jamfHelper

heading="Please wait.  Preparing the macOS Catalina upgrade..."

##Title to be used for jamfHelper

description="

This process may take several minutes.

Once completed your computer will reboot and begin the upgrade."

##Icon to be used for jamfHelper

icon=/Applications/Install\ macOS\ Catalina.app/Contents/Resources/InstallAssistant.icns

##Launch jamfHelper

/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType fs -title "" -icon "$icon" -heading "$heading" -description "$description" &

##Start macOS Catalina Upgrade

/Applications/Install\ macOS\ Catalina.app/Contents/Resources/startosinstall --agreetolicense --forcequitapps

exit 0
