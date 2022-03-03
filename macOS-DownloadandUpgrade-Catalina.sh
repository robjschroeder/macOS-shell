#!/bin/sh

# Script used to download and install macOS 10.15.7 Catalina
#
# @robjschroeder

# Reset any ingored software updates
softwareUpdate --reset-ignored
# Download 10.15.7
softwareUpdate --fetch-full-installer --full-installer-version 10.15.7
# Run the startosinstall binary
/Applications/Install\ macOS\ Catalina.app/Contents/Resources/startosinstall --agreetolicense --forcequitapps
