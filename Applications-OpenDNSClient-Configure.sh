#!/bin/bash

# This script will configure the OpenDNS
# Roaming Client for macOS. 
#
# Updated: 2.23.2022 @ Robjschroeder
#
# Variables
APIFingerprint="fingerprint"
APIOrganizationID="OrgID"
APIUserID="UserID"

# Make the OpenDNS Roaming Client Directory
mkdir -p "/Library/Application Support/OpenDNS Roaming Client/"
# Build plist
DATA='<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>APIFingerprint</key>
<string>'$APIFingerprint'</string>
<key>APIOrganizationID</key>
<string>'$APIOrganizationID'</string>
<key>APIUserID</key>
<string>'$APIUserID'</string>
<key>InstallMenubar</key>
<true/>
</dict>
</plist>'
echo "$DATA" > "/Library/Application Support/OpenDNS Roaming Client/OrgInfo.plist"

exit 0
