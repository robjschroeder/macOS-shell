#!/bin/bash

# Script will download Monterey and create a bootable ISO to be used with VMWare
#
# Created: 4.5.2022 @robjschroeder
#

#Get macOS Monterey
softwareupdate --fetch-full-installer

# Create temporary empty disk image
hdiutil create -o /tmp/Monterey -size 16384m -volname Monterey -layout SPUD -fs HFS+J

# Mount the disk image at /Volumes/Monterey
hdiutil attach /tmp/Monterey.dmg -noverify -mountpoint /Volumes/Monterey

# Create bootable disk image using createinstallmedia
/Applications/Install\ macOS\ Monterey.app/Contents/Resources/createinstallmedia --volume /Volumes/Monterey --nointeraction

# Unmount the disk image
hdiutil eject -force /Volumes/Install\ macOS\ Monterey\

# Convert the disk image to ISO
hdiutil convert /tmp/Monterey.dmg -format UDTO -o ~/Desktop/Monterey

mv -v ~/Desktop/Monterey.cdr ~/Desktop/Monterey.iso

# Remove the disk image
sudo rm -fv /tmp/Monterey.dmg
