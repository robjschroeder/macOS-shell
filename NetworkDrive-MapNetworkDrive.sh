#!/bin/bash

# This script can be used to mount
# a network share. This is meant to be
# used with a policy in Jamf Pro.
#
# Updated: 2.23.2022 @ Robjschroeder
#
# Jamf Pro script parameters: 
# $4 = protocol to connect with (afp | smb)
# $5 = address of the server, e.g. my.fileserver.com
# $6 = name of the share to mount

UID1=$(id -u $3)
    echo "UID: $UID1"
protocol="$4"
    echo "Protocol: $4"
serverName="$5"
    echo "Server: $5"
shareName="$6"
    echo "Sharename: $6"
      # Mount the drive 
        mount_script=`/usr/bin/osascript  > /dev/null << EOT
        tell application "Finder"
        mount volume "$protocol://${serverName}/${shareName}"
        end tell
EOT`
exit
