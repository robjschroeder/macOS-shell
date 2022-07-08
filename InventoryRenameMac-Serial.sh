#!/bin/sh

# Renames computer locally to the serial number
# of the computer, then updates the Jamf Pro record
#
# Created: 05.03.2022 @ Robjschroeder

# Get the serial number of the computer
serial=$(/usr/sbin/system_profiler SPHardwareDataType | awk '/Serial/ {print $NF}')

# Get original name of computer
oldComputerName=$(/usr/sbin/scutil --get ComputerName)

# Generate new computer name
computerName=${serial}

# Set new computer name locally
/usr/sbin/scutil --set ComputerName ${computerName}

/usr/sbin/scutil --set HostName ${computerName}

/usr/sbin/scutil --set LocalHostName ${computerName}

# Set the computer name in Jamf to reflect what is set locally on the computer
/usr/local/bin/jamf setComputerName -name ${computerName}
/usr/local/bin/jamf recon

echo "Computer name has been changed from ${oldComputerName} to ${computerName}"

exit 0
