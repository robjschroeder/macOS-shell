#!/bin/sh

UID1=$(id -u $3)
    echo "UID: $UID1"
protocol="$4" # This is the protocol to connect with (afp | smb)
    echo "Protocol: $4"
serverName="$5"   # This is the address of the server, e.g. my.fileserver.com
    echo "Server: $5"
shareName="$6"    # This is the name of the share to mount
    echo "Sharename: $6"
      # Mount the drive 
        mount_script=`/usr/bin/osascript  > /dev/null << EOT
        tell application "Finder"
        mount volume "$protocol://${serverName}/${shareName}"
        end tell
EOT`
exit