#!/bin/bash

####################################################################################################
#
# Copyright (c) 2014, JAMF Software, LLC.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the JAMF Software, LLC nor the
#                 names of its contributors may be used to endorse or promote products
#                 derived from this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
####################################################################################################
#
#	DESCRIPTION
#
#	This script was designed to read full JSS Summaries generated from version 9+.
#	The script will parse through the summary and return back a set of data that
#	should be useful when performing JSS Health Checks.
#
####################################################################################################
# 
#	HISTORY
#
#	Version 1.0 Created by Sam Fortuna on June 13th, 2014
#	Version 1.1 Updated by Sam Fortuna on June 17th, 2014
#		-Fixed issues with parsing some data types
#		-Added comments for readability
#		-Added output about check-in information
#		-Added database size parsing
#	Version 1.2 Updated by Nick Anderson August 4, 2014
#		-Added recommendations to some displayed items
#	Version 1.3 Updated by Nick Anderson on October 14, 2014
#		-Fixed the way echo works in some terminals
#	Version 1.4a Updated by Nick Anderson
#		-Check certificate expiration dates
#	Version 1.5 Updated by Sam Fortuna January 22, 2015
#		-Added check for 10+ criteria smart groups
#		-Simplified recommendations
#	Version 2.0 Updated by Sam Fortuna February 28, 2015
#		-Fixed an issue gathering ongoing update inventory policies
#		-Updated to support changes to 9.65 JSS Summaries
#	Version 2.1 Updated by Sam Fortuna March 24, 2015
#		-Added smart group counters
#		-Added log file location check
#	Version 2.2 Updated by Sam Fortuna May 26, 2015
#		-Fixed an issue parsing smart group names that included periods
#		-Added total criteria count to potentially problematic group identification
#		-Added VPP expiration output
#	Version 2.3 Updated by Sam Fortuna June 4, 2015
#		-Fixed table size parsing
#	Version 2.4 Updated by Sam Fortuna July 2, 2015
#		-Added nested smart group checks
#	Version 3.0 Updated by Matthew Mitchell June 16, 2017
#		-Added compatibility for 9.99 changes, including tvOS
#	Version 3.1 Updated by Matthew Mitchell July 26, 2017
#		-Fixed some bad logic with the 3.0 update
#		-Added support for SSL Verification
#	Version 3.2 Updated by Matthew Mitchell August 18, 2017
#		-Added support for 9.100 and later versions
#	Version 3.3 Updated by Robert Schroeder July 14, 2022
#		-Changed SSL Expiration logic to look for "Expires" as well since that was coming back as the variable
#		-Changed all '`...`' statements to use '$()'
#		-Removed python from script, changing to use bash for gathering expiration dates
#		-Added variables section, if file is not defined, terminal will ask for the file
#		-Increased subInfo variable to 150 lines since not all information was not being included
#
#
####################################################################################################

##################################################
# Variables -- edit as needed

# Jamf Pro Summary file location
file=""

##################################################

# If file path not defined, prompt for file location
if [[ ${file} = "" ]]; then
	read -p "Drag your JPS Summary into terminal: " file
fi

# Read in file data
data=$(cat ${file})
if [[ ${data} == "" ]]; then
	echo "Unable to read the file path specified"
	echo "Ensure there are no spaces and that the path is correct"
	exit 1
fi

# Check echo mode in Terminal and set -e, if needed
echotest=$(echo -e "test")
if [[ ${echotest} == "test" ]]; then
	echomode="-e"
else
	echomode=""
fi

# Break the summary into smaller chunks
# Get first 75 lines of the summary
basicInfo=$(head -n 75 ${file})

jssVersionString=$(echo $echomode "$basicInfo" | awk '/Installed Version/ {print $NF}' | cut -d '-' -f1 | sed 's/\.//g')

is999Later=false

# Find the line number that includes clustering information
lineNum=$(cat ${file} | grep -n "Clustering Enabled" | awk -F : '{print $1}')

# Store 100 lines after clustering information
subInfo=$(head -n $((${lineNum} + 150)) ${file} | tail -n 151)

# Find the line number for the Push Certificate subject
pushExpiration=$(echo "$subInfo" | grep -n "com.apple.mgmt" | awk -F : '{print $1}')

# Find the line number that inclues checkin frequency information
lineNum=$(cat ${file} | grep -n "Check-in Frequency" | awk -F : '{print $1}')

# Store 30 lines after the Check-in Frequency information begins
checkInInfo=$(head -n $((${lineNum} + 30)) ${file} | tail -n 31)

# Store last 325 lines to check database table sizes
dbInfo=$(tail -n 325 ${file})

# Determine whether clustering is enabled
clustering=$(echo "$subInfo" | awk '/Clustering Enabled/ {print $NF}')

# Find the models of printers and determine whether none, some, or xerox for max packet size
findPrinters=$(cat ${file} | grep -B 1 "CUPS Name" | grep -v "CUPS Name")
xeroxPrinters=$(echo $findPrinters | grep "Xerox")

# Gather the number of devices
computers=$(echo "$basicInfo" | awk '/Managed Computers/ {print $NF}')
mobiles=$(echo "$basicInfo" | awk '/Managed Mobile Devices/ {print $NF}')
if [[ ${mobiles} == "" ]]; then
	mobiles=$(echo "$basicInfo" | awk '/Managed iOS Devices/ {print $NF}')
	is999Later=true 
fi
totalDevices=$(( $computers + $mobiles ))

# Find today's epoch time
todayEPOCH=$(date +"%s")

#Sort our summary into a performance bracket based on number of devices total
if (( $totalDevices < 501 )) ; then
	echo "Bracket shown for 1-500 Devices"
	poolsizerec="45"
	sqlconnectionsrec="Default of 151 is good"
	httpthreadsrec="150"
	clusterrec="Unnecessary"
elif (( $totalDevices < 1001 )) ; then
	echo "Bracket shown for 501-1000 Devices"
	poolsizerec="45"
	sqlconnectionsrec="Default of 151 is good"
	httpthreadsrec="300"
	clusterrec="Unnecessary"
elif (( $totalDevices < 2001 )) ; then
	echo "Bracket shown for 1001-2000 Devices"
	poolsizerec="45"
	sqlconnectionsrec="Default of 151 is good"
	httpthreadsrec="500"
	clusterrec="Consider Load Balancing"
elif (( $totalDevices < 5001 )) ; then
	echo "Bracket shown for 2001-5000 Devices"
	poolsizerec="45"
	sqlconnectionsrec="Default of 151 is good"
	httpthreadsrec="1000"
	clusterrec="Consider Load Balancing"
else
	echo "Bracket shown for > 5000 Devices."
	poolsizerec="Too many variables to determine a standard default recommendation"
	sqlconnectionsrec="Too many variables to determine a standard default recommendation"
	httpthreadsrec="Too many variables to determine a standard default recommendation"
	clusterrec="Load Balancing"
fi

# Find the current max packet size for our maxpacket-in-relation-to-current-setting-and-printers logic
curmaxpacket=$(echo $echomode "$(($(echo "$basicInfo" | awk '/max_allowed_packet/ {print $NF}')/ 1048576))")

if [[ "$findprinters" == "" ]] ; then			#If we found no printers, then
	if (( $curmaxpacket < 17 )) ; then			#check to see if our current packet size is lower or equal to 16
		maxpacketrec="16 MB"					#if it is lower or recommended, recommend 16
	elif (( $curmaxpacket > 15 )) ; then		#if it's higher than recommended
		maxpacketrec="Current Setting"			#don't change it
	fi
elif [[ "$xeroxprinters" != "" ]] ; then		#then if the return for searching 'xerox' isn't blank
	maxpacketrec="512 MB"						#recommend a giant packet size
elif [[ "$findprinters" != "" ]] ;then			#but if they're other brand printers
	maxpacketrec="64 MB"						#just increase packet size to 64
else
	maxpacketrec="Unable to determine"			#"slightly better than a blank result"
fi

#Parse the data and print out the results
echo $echomode "JSS Version: \t\t\t\t $(echo "$basicInfo" | awk '/Installed Version/ {print $NF}')"
echo $echomode "Managed Computers: \t\t\t $computers"
echo $echomode "Managed iOS Devices: \t\t $mobiles"

if (( $is999Later == "true" )) ; then
	tvOSlater=$(echo "$basicInfo" | grep "Managed Apple TV Devices" | awk 'NR==1 {print $NF}')
	tvOSearlier=$(echo "$basicInfo" | grep "Managed Apple TV Devices" | awk 'NR==2 {print $NF}')
	tvs="$(( $tvOSlater + $tvOSearlier ))"
	echo $echomode "Managed tvOS Devices: \t\t $tvs"
fi

echo $echomode "Server OS: \t\t\t\t\t $(echo "$basicInfo" | grep "Operating System" | awk '{for (i=3; i<NF; i++) printf $i " "; print $NF}')"
echo $echomode "Java Version: \t\t\t\t $(echo "$basicInfo" | awk '/Java Version/ {print $NF}')"
echo $echomode "Database Size: \t\t\t\t $(echo "$basicInfo" | grep "Database Size" | awk 'NR==1 {print $(NF-1),$NF}')"
echo $echomode "Maximum Pool Size:  \t\t\t $(echo "$basicInfo" | awk '/Maximum Pool Size/ {print $NF}') \t$(tput setaf 2)Recommended: $poolsizerec$(tput sgr0)"
echo $echomode "Maximum MySQL Connections: \t $(echo "$basicInfo" | awk '/max_connections/ {print $NF}') \t$(tput setaf 2)Recommended: $sqlconnectionsrec$(tput sgr0)"

#Alert if binary logging is enabled
binlogging=$(echo "$basicInfo" | awk '/log_bin/ {print $NF}')
if [ "$binlogging" = "OFF" ] ; then
	echo $echomode "Bin Logging: \t\t\t\t $(echo "$basicInfo" | awk '/log_bin/ {print $NF}') \t$(tput setaf 2)✓$(tput sgr0)"
else
	echo $echomode "Bin Logging: \t\t\t\t $(echo "$basicInfo" | awk '/log_bin/ {print $NF}') \t$(tput setaf 9)Is there a reason binary logging is enabled (MySQL Replication)?\t[!]$(tput sgr0)"
fi
echo $echomode "Max Allowed Packet Size: \t $(($(echo "$basicInfo" | awk '/max_allowed_packet/ {print $NF}')/ 1048576)) MB $(tput setaf 2)Recommended: $maxpacketrec$(tput sgr0)"
echo $echomode "MySQL Version: \t\t\t\t $(echo "$basicInfo" | awk '/version ..................../ {print $NF}')"

#Alert user to change management being disabled
changemanagement=$(echo "$subInfo" | awk '/Use Log File/ {print $NF}')
if [ "$changemanagement" = "false" ] ; then
	echo $echomode "Change Management Enabled: \t $(echo "$subInfo" | awk '/Use Log File/ {print $NF}') \t$(tput setaf 2)Recommended: On$(tput sgr0)"
else
	echo $echomode "Change Management Enabled: \t $(echo "$subInfo" | awk '/Use Log File/ {print $NF}') \t$(tput setaf 2)✓$(tput sgr0)"
fi

# Check log path against current operating system version, if non-default show warning
logpath=$(echo $echomode $(echo "$subInfo" | awk -F . '/Location of Log File/ {print $NF}'))
findos=$(echo $echomode $(echo "$basicInfo" | grep "Operating System" | awk '{for (i=3; i<NF; i++) printf $i " "; print $NF}'))
detectosx=$(echo $findos | grep Mac)
detectlinux=$(echo $findos | grep Linux)
detectwindows=$(echo $findos | grep Windows)
if [[ "$detectosx" != "" ]] ; then
	if [[ "$logpath" = "/Library/JSS/Logs" ]] ; then
		echo $echomode "Log File Location: \t\t\t $(echo "$subInfo" | awk -F . '/Location of Log File/ {print $NF}')"
	else
		echo $echomode "Log File Location: \t\t\t $(echo "$subInfo" | awk -F . '/Location of Log File/ {print $NF}')\t$(tput setaf 9)Path doesn't match server OS❗$(tput sgr0)"
	fi
elif [[ "$detectlinux" != "" ]] ; then
	if [[ "$logpath" = "/usr/local/jss/logs" ]] ; then # Probably not going to be universal
		echo $echomode "Log File Location: \t\t\t $(echo "$subInfo" | awk -F . '/Location of Log File/ {print $NF}')"
	else
		echo $echomode "Log File Location: \t\t\t $(echo "$subInfo" | awk -F . '/Location of Log File/ {print $NF}')\t$(tput setaf 9)Path doesn't match server OS❗$(tput sgr0)"
	fi
elif [[ "$detectwindows" != "" ]] ; then
	if [[ "$logpath" = "C:\Program Files\JSS\Logs" ]] ; then # Does this path have a capital L in Logs?
		echo $echomode "Log File Location: \t\t\t $(echo "$subInfo" | awk -F . '/Location of Log File/ {print $NF}')"
	else
		echo $echomode "Log File Location: \t\t\t $(echo "$subInfo" | awk -F . '/Location of Log File/ {print $NF}') \t$(tput setaf 9)Path doesn't match server OS❗$(tput sgr0)"
	fi
else
	echo $echomode "Log File Location: \t\t\t $(echo "$subInfo" | awk -F . '/Location of Log File/ {print $NF}')"
fi

#Search for the built-in name in the SSL subject, if it is not detected it must be a third party cert or broken so alert user
sslsubject=$(echo "$subInfo" | awk '/SSL Cert Subject/ {$1=$2=$3="";print $0}' | grep "O=JAMF Software")
if [ "$sslsubject" = "" ] ; then
	echo $echomode "SSL Certificate Subject: \t $(echo "$subInfo" | awk '/SSL Cert Subject/ {$1=$2=$3="";print $0}') $(tput setaf 9)[!]$(tput sgr0)"
else
	echo $echomode "SSL Certificate Subject: \t      $(echo "$subInfo" | awk '/SSL Cert Subject/ {$1=$2=$3="";print $0}')"
fi

ssldate=$(echo "$subInfo" | awk '/SSL Cert Expires/ {print $NF}')
if [[ "$ssldate" != "" && "$ssldate" != "Expires" ]]; then
	sslepoch=$(date -jf "%Y/%m/%d %H:%M" "$ssldate 00:00" +"%s")		#convert it to unix epoch
	ssldifference=$(( "$sslepoch" - "$todayEPOCH" ))				#subtract ssl epoch from today's epoch
	sslresult=$(($ssldifference/86400))					#divide by number of seconds in a day to get remaining days to expiration
	
	#If ssl is expiring in under 60 days, output remaining days in red instead of green
	if (( $sslresult > 60 )) ; then
		echo $echomode "SSL Certificate Expiration: \t\t $(echo "$subInfo" | awk '/SSL Cert Expires/ {print $NF}') \t$(tput setaf 2)$sslresult Days$(tput sgr0)"
	else
		echo $echomode "SSL Certificate Expiration: \t\t $(echo "$subInfo" | awk '/SSL Cert Expires/ {print $NF}') \t$(tput setaf 9)$sslresult Days$(tput sgr0)"
	fi
	
else
	echo $echomode "SSL Certification Expiration: Not Found"
fi

echo $echomode "HTTP Threads: \t\t\t\t $(echo "$subInfo" | awk '/HTTP Connector/ {print $NF}') \t$(tput setaf 2)Recommended: $httpthreadsrec$(tput sgr0)"
echo $echomode "HTTPS Threads: \t\t\t\t $(echo "$subInfo" | awk '/HTTPS Connector/ {print $NF}') \t$(tput setaf 2)Recommended: $httpthreadsrec$(tput sgr0)"
echo $echomode "JSS URL: \t\t\t\t\t $(echo "$subInfo" | awk '/HTTPS URL/ {print $NF}')"

apnsdate=$(echo "$subInfo" | grep "Expires" | awk 'NR==2 {print $NF}')

if [[ "$apnsdate" != "" ]]; then
	
	apnsepoch=$(date -jf "%Y/%m/%d %H:%M" "$apnsdate 00:00" +"%s")		#convert it to unix epoch
	apnsdifference=$(( "$apnsepoch" - "$todayEPOCH" ))				#subtract apns epoch from today's epoch
	apnsresult=$(( $apnsdifference/86400 ))				#divide by number of seconds in a day to get remaining days to expiration
	
	#If apns is expiring in under 60 days, output remaining days in red instead of green
	if (( $apnsresult > 60 )) ; then
		echo $echomode "APNS Expiration: \t\t\t $(echo "$subInfo" | grep "Expires" | awk 'NR==2 {print $NF}') \t$(tput setaf 2)$apnsresult Days$(tput sgr0)"
	else
		echo $echomode "APNS Expiration: \t\t\t $(echo "$subInfo" | grep "Expires" | awk 'NR==2 {print $NF}') \t$(tput setaf 9)$apnsresult Days$(tput sgr0)"
	fi
	
else
	echo $echomode "APNS Expiration: \t\t\t Not Found"
fi

vppdate=$(cat $file | grep -A 100 "VPP Accounts" | awk '/Expiration Date/ {print $NF}')	#get the current vpp expiration date
if [[ -n $vppdate ]] ; then
	for i in $vppdate; do
		vppepoch=$(date -jf "%Y/%m/%d %H:%M" "$i 00:00" +"%s")				#convert it to unix epoch
		vppdifference=$(( "$vppepoch" - "$todayEPOCH" ))				#subtract vpp epoch from today's epoch
		vppresult=$(( $vppdifference/86400 ))					#divide by number of seconds in a day to get remaining days to expiration
		
		#If vpp token is expiring in under 60 days, output remaining days in red instead of green
		if (( $vppresult > 60 )) ; then
			echo $echomode "VPP Token Expiration: \t\t $i \t$(tput setaf 2)$vppresult Days$(tput sgr0)"
		else
			echo $echomode "VPP Token Expiration: \t\t $i \t$(tput setaf 9)$vppresult Days$(tput sgr0)"
		fi
	done
fi

#Detect whether external CA is enabled and warn user
thirdpartycert=$(echo "$subInfo" | awk '/External CA enabled/ {print $NF}')
if [ "$thirdpartycert" = "false" ] ; then
	echo $echomode "External CA Enabled: \t\t $(echo "$subInfo" | awk '/External CA enabled/ {print $NF}')"
else
	echo $echomode "External CA Enabled: \t\t $(echo "$(tput setaf 3)$subInfo" | awk '/External CA enabled/ {print $NF}') \t$(tput setaf 9)[!]$(tput sgr0)"
fi
echo $echomode "Log Flushing Time: \t\t\t $(echo "$subInfo" | grep "Each Day" | awk '{for (i=7; i<NF; i++) printf $i " "; print $NF}') \t$(tput setaf 2)Recommended: Stagger time from nightly backup$(tput sgr0)"

#Check how many logs are set to flush and if 0 display a check
logflushing=$(echo "$subInfo" | awk '/Do not flush/ {print $0}' | wc -l)
if ! (( $logflushing < 1 )) ; then
	echo $echomode "Number of logs set to NOT flush:  $(echo "$subInfo" | awk '/Do not flush/ {print $0}' | wc -l) \t$(tput setaf 2)Recommended: Enable log flushing$(tput sgr0)"
else
	echo $echomode "Number of logs set to NOT flush:  $(echo "$subInfo" | awk '/Do not flush/ {print $0}' | wc -l) \t$(tput setaf 2)✓$(tput sgr0)"
fi

#Add up the number of logs set to not flush in under 3 months (includes logs set not to flush)
logflushing6months=$(echo "$subInfo" | awk '/6 month/ {print $0}' | wc -l)
logflushing1year=$(echo "$subInfo" | awk '/1 year/ {print $0}' | wc -l)
notlogflushing3months="$(( $logflushing6months + $logflushing1year + $logflushing ))"
# if all logs are set to flush under 3 months display a check
if ! (( $notlogflushing3months < 1 )) ; then
	echo $echomode "Logs not flushing in under 3 months:     $notlogflushing3months \t$(tput setaf 2)Recommended: Ask if there's a reason for keeping logs for 3 months or more$(tput sgr0)"
else
	echo $echomode "Logs not flushing in  under 3 months:    $notlogflushing3months \t$(tput setaf 2)✓$(tput sgr0)"
fi

echo $echomode "Check in Frequency: \t\t\t $(echo "$checkInInfo" | awk '/Check-in Frequency/ {print $NF}')"
echo $echomode "Login/Logout Hooks enabled: \t $(echo "$checkInInfo" | awk '/Logout Hooks/ {print $NF}')"
echo $echomode "Startup Script enabled: \t\t $(echo "$checkInInfo" | awk '/Startup Script/ {print $NF}')"
echo $echomode "Flush history on re-enroll: \t $(echo "$checkInInfo" | awk '/Flush history on re-enroll/ {print $NF}')"
echo $echomode "Flush location info on re-enroll: \t $(echo "$checkInInfo" | awk '/Flush location information on re-enroll/ {print $NF}')"

#Warn user if push notifications are disabled
pushnotifications=$(echo "$checkInInfo" | awk '/Push Notifications Enabled/ {print $NF}')
if [ "$pushnotifications" = "true" ] ; then
	echo $echomode "Push Notifications enabled: \t $(echo "$checkInInfo" | awk '/Push Notifications Enabled/ {print $NF}')"
else
	echo $echomode "Push Notifications enabled: \t $(echo "$checkInInfo" | awk '/Push Notifications Enabled/ {print $NF}') \t$(tput setaf 9)[!]$(tput sgr0)"
fi

sslverification=$(echo "$checkInInfo" | awk '/Certificate must be valid/ {print $NF}')
echo $echomode "SSL Verification: \t\t\t $sslverification"

echo $echomode "Number of Extension Attributes: \t $(cat $file | grep "Mac Script" | wc -l | awk '{print $NF}')"
echo $echomode "Number of Network Segments: \t\t $(cat $file | grep "Starting Address" | wc -l | awk '{print $NF}')"
echo $echomode "Number of LDAP Servers: \t\t $(cat $file | grep "Wildcard Searches" | wc -l | awk '{print $NF}')"

#Alert user to clustering recommendation if not enabled, otherwise warn user if enabled
if [[ "$clustering" = "false" ]] ; then
	echo $echomode "Clustering Enabled: \t\t\t $(echo "$subInfo" | awk '/Clustering Enabled/ {print $NF}') \t$(tput setaf 2)Recommended: $clusterrec$(tput sgr0)"
elif [ "$clustering" = "true" ] ; then
	echo $echomode "Clustering Enabled: \t\t\t $(echo "$subInfo" | awk '/Clustering Enabled/ {print $NF}') \t$(tput setaf 9)[!]$(tput sgr0)"
	clusterFrequency=$(echo "$subInfo" | awk '/Monitor Frequency/ {print $NF}')
	if [ "$clusterFrequency" != "60" ]; then
		echo "Cluster frequency not default: \t\t $clusterFrequency \t$(tput setaf 9)[!]$(tput sgr0)"
	fi
else
	echo $echomode "Clustering Enabled: \t\t\t $(echo "$subInfo" | awk '/Clustering Enabled/ {print $NF}') \t$(tput setaf 9)$(tput sgr0)"
fi

#Check for database tables over 1 GB in size
echo $echomode
echo $echomode "Tables over 1 GB in size:"
largeTables=$(echo "$dbInfo" | awk '/GB/ {print $1, "\t", "\t", $(NF-1), $NF}')
if [ "$largeTables" != "" ]; then
	echo $echomode "$largeTables" "\t$(tput setaf 9)[!]$(tput sgr0)"
else
	echo $echomode "None \t$(tput setaf 2)✓$(tput sgr0)"
fi

#Find problematic policies that are ongoing, enabled, update inventory and have a scope defined
list=$(cat $file| grep -n "Ongoing" | awk -F : '{print $1}')

echo $echomode
echo $echomode "The following policies are Ongoing, Enabled and update inventory:"

for i in $list 
do
	
	#Check if policy is enabled
	test=$(head -n $i $file | tail -n 13)
	enabled=$(echo $echomode "$test" | awk /'Enabled/ {print $NF}')
	
	#Check if policy has an active trigger
	if [[ "$enabled" == "true" ]]; then
		trigger=$(echo $echomode "$test" | grep Triggered | awk '/true/ {print $NF}')
	fi
	
	#Check if the policy updates inventory
	if [[ "$enabled" == "true" ]]; then
		line=$(($i + 40))
		inventory=$(head -n $line $file | tail -n 15 | awk '/Update Inventory/ {print $NF}')
	fi
	
	#Get the name and scope of the policy
	if [[ "$trigger" == *"true"* && "$inventory" == "true" && "$enabled" == "true" ]]; then
		scope=$(head -n $(($i + 5)) $file |tail -n 5 | awk '/Scope/ {$1=""; print $0}')
		name=$(echo $echomode "$test" | awk -F '[\.]+[\.]' '/Name/ {print $NF}')
		echo $echomode $(tput setaf 6)"Name: \t $name" $(tput sgr0)
		echo $echomode "Scope: \t $scope"
	fi
done

echo $echomode
echo $echomode "The following policies are Ongoing at recurring check-in, but do not update inventory:"

for i in $list 
do
	#Check if policy is enabled
	test=$(head -n $i $file | tail -n 13)
	enabled=$(echo $echomode "$test" | awk /'Enabled/ {print $NF}')
	
	#Check if policy is on the recurring trigger
	if [[ "$enabled" == "true" ]]; then
		recurring=$(echo $echomode "$test" | awk '/Triggered by Check-in/ {print $NF}')
	fi
	
	#Check if the policy updates inventory
	if [[ "$enabled" == "true" ]]; then
		line=$(($i + 40))
		inventory=$(head -n $line $file | tail -n 15 | awk '/Update Inventory/ {print $NF}')
	fi
	
	#Get the scope
	scope=$(head -n $(($i + 5)) $file |tail -n 5 | awk '/Scope/ {$1=""; print $0}')
	
	#Get the name of the policy
	if [[ "$recurring" == "true" && "$inventory" == "false" && "$enabled" == "true" ]]; then
		name=$(echo $echomode "$test" | awk -F '[\.]+[\.]' '/Name/ {print $NF}')
		echo $echomode $(tput setaf 6)"Name: \t $name" $(tput sgr0)
		echo $echomode "Scope: \t $scope"
	fi
done

#Count number of policies that update inventory once per day
list2=$(cat $file| grep -n "Once every day" | awk -F : '{print $1}')

#Create a counter
inventoryDaily=0

for i in $list2
do
	
	#Check if policy is enabled
	test=$(head -n $i $file | tail -n 13)
	enabled=$(echo $echomode "$test" | awk /'Enabled/ {print $NF}')
	
	#Check if policy has an active trigger
	if [[ "$enabled" == "true" ]]; then
		trigger=$(echo $echomode "$test" | grep Triggered | awk '/true/ {print $NF}')
	fi
	
	#Check if the policy updates inventory
	if [[ "$enabled" == "true" ]]; then
		line=$(($i + 40))
		inventory=$(head -n $line $file | tail -n 15 | awk '/Update Inventory/ {print $NF}')
	fi
	
	
	
	#Increment count if all above criteria are true
	if [[ "$trigger" == *"true"* && "$inventory" == "true" && "$enabled" == "true" ]]; then
		let inventoryDaily=inventoryDaily+1
	fi
done

echo $echomode
echo $echomode "There are" $inventoryDaily "policies that update inventory daily."

#List smart group names that include 10 or more criteria
echo $echomode
echo $echomode "The following smart groups have 10+ criteria or 4+ nested criteria:"
echo $echomode

while read line
do
	#Count current line number
	let lineNumber=lineNumber+1
	
	if [[ "${line}" == *"Smart Computer Groups"* ]]; then
		lineNumber=$(cat $file | awk '/Smart Computer Groups/{print NR; exit}')
		echo $echomode $line":"
		groups=0
	elif [[ "${line}" == *"Smart Mobile Device Groups"* ]]; then
		echo $echomode "$(tput setaf 8)Total number of smart groups: $groups$(tput sgr0)"
		echo $echomode
		echo $echomode $line":"
		groups=0
	elif [[ "${line}" == *"User Groups"* ]]; then
		echo $echomode "$(tput setaf 8)Total number of smart groups: $groups$(tput sgr0)"
		echo $echomode
		echo $echomode $line":"
		groups=0
	elif [[ "${line}" == *"Device Enrollment Program"* ]]; then
		echo $echomode "$(tput setaf 8)Total number of smart groups: $groups$(tput sgr0)"
	fi
	
	#Start counting number of criteria per group
	if [[ "${line}" == *"Membership Criteria"* ]]; then
		counter=1
		let groups=groups+1
		
		#Check for nested groups
		if [[ "${line}" == *"member of"* ]]; then
			nested=1
		else
			nested=0
		fi
		
		#Increment for each criteria found
	elif [[ "${line}" == *"- and -"* || "${line}" == *"- or -"* ]]; then
		let counter=counter+1
		
		#Check for nested groups
		if [[ "${line}" == *"member of"* ]]; then
			let nested=nested+1
		fi
		
		if [ $nested -eq 4 ]; then
			lineName=$(($lineNumber-$counter-1))
			nestedName=$(head -n $lineName $file | tail -n 1 | awk -F '[\.]+[\ ]' '{print $NF}')
			if [[ "$nestedName" == *"Site "* ]]; then
				lineName=$(($lineNumber-$counter-2))
				nestedName=$(head -n $lineName $file | tail -n 1 | awk -F '[\.]+[\ ]' '{print $NF}')
			fi
		fi
		
		#Print the group names that have more than 10 criteria
		if [ $counter -eq 10 ]; then
			name=$(($lineNumber-11))
			groupName=$(head -n $name $file | tail -n 1 | awk -F '[\.]+[\ ]' '{print $NF}')
			if [[ "$groupName" == *"Site "* ]]; then
				name=$(($lineNumber-12))
				groupName=$(head -n $name $file | tail -n 1 | awk -F '[\.]+[\ ]' '{print $NF}')
			fi
		fi
	elif [[ "${line}" == *"==="* && $counter -ge 10 ]]; then
		if [ $nested -gt 3 ]; then
			echo $echomode "$(tput setaf 6)$groupName \t\t $(tput setaf 9)$counter criteria, $nested nested groups$(tput sgr0)"
			counter=1
			nested=0
		else
			echo $echomode "$(tput setaf 6)$groupName \t\t $(tput setaf 9)$counter criteria,$(tput sgr0) $nested nested groups"
			counter=1
		fi
	elif [[ "${line}" == *"==="* && $nested -gt 3 && $counter -lt 10 ]]; then
		echo $echomode "$(tput setaf 6)$nestedName \t\t $(tput sgr0)$counter criteria, $(tput setaf 9)$nested nested groups$(tput sgr0)"
		nested=0
	fi
done < $file
