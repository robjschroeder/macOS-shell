#!/bin/bash

# Sets macName variable
macName=`scutil --get ComputerName`

# Sets local host to computer name and rename HD
/usr/sbin/scutil --set LocalHostName $macName
/usr/sbin/scutil --set HostName $macName
/usr/sbin/diskutil rename / $macName