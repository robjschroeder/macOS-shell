#!/bin/sh

####################################################################################################
#
# Google Chrome Installation Script
#
####################################################################################################
#
# DESCRIPTION
#
# Automatically download and install Google Chrome
#
####################################################################################################
# 
#
# Google Chrome Installation script

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
