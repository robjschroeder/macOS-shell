#!/bin/sh
#
# Upgrads macOS to Catalina using the startosinstall
# from the installer located in /Applications
# @robjschroeder
#

# Reset ignored software updates, if any
softwareUpdate --reset-ignored
# Run startosinstall
/Applications/Install\ macOS\ Catalina.app/Contents/Resources/startosinstall --agreetolicense --forcequitapps
