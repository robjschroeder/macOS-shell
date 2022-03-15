#!/bin/bash
####################################################################################################
#
# Copyright (c) 2015, JAMF Software, LLC.  All rights reserved.
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
#      General Change log
#
#       v0.0 - General Usage and creation // 11.17.2015
#           Matthew Boyle
#
#       v0.1 - Added a function to echo how many times a unique error was generated on a specific
#       day.  If the error was logged once, there is no count echoed in the log.
#           Lucas Vance 3/9/17
#
#       v0.2 - Added In line Log location
#               - Added Blank Push ID Collection and filtering
#               - Added Cleanup, Sumarzing of Common Flood Errors and Editable Variables
#               - Added Additional Files for Saving Error information
#
####################################################################################################
#
#      Purpose and Use
#
#       This script will read through the JAMFServerSoftware.log and output all errors and warnings
#       into a condensed log file, with repetitive errors removed.
#
####################################################################################################
#
#      Instructions
#       Run the script and direct it to your log file
#       Optional Run script with location of log behind it
#       e.g. sh logParsh.sh ~/Downloads/JAMFSoftwareServer.log
#       The script will read the total amount of days the log captured
#       The user will be prompted with the available days to read consecutively
#           with the users choice of program to open log files with
#
####################################################################################################
#
#       Editable Variables
#       fileLoc = The location of the Fie Output
#           uuidCSVFile = Name of the File to store the UUIDs to
#           newLog = Name of the File to save the Parsed Log as
#           mdmReturnFile = Name of File to save MDM Returned Errors
#           saveBlankPushToCSV = Yes or No, Save the Blank Push ID's to CSV
#           saveMDMReturntoCSV = Yes or No, Save UUID and Command Information to CSV
#
####################################################################################################
fileLoc="/tmp"
uuidCSVFile="blankUUID.csv"
newLog="filtered_JAMFSoftwareServer.log"
mdmReturnFile="mdmReturns.csv"
saveBlankPushToCSV="Yes"
saveMDMReturntoCSV="Yes"
####################################################################################################
#
#               Do not Edit Below
#
####################################################################################################
sortedLog="${fileLoc}/${newLog}"
sortedUUID="${fileLoc}/${uuidCSVFile}"
sortedMDMReturn="${fileLoc}/${mdmReturnFile}"
bpcount=0
mdmcount=0
# user input and prompts
if [ ! -z "$1" ]; then
    logInFile="$1"
else
read -p "Log file location: " logInFile
fi
#cat "${logInFile}" | grep '\[ERROR\|\[WARN' > /tmp/jssTmp.log
#logFile="/tmp/jssTmp.log"
logFile="${logInFile}"
echo "$(tput setaf 1)"
cat << "EOF"
       _,.
     ,` -.)
    '( _/'-\\-.
   /,|`--._,-^|            ,
   \_| |`-._/||          ,'|
     |  `-, / |         /  /
     |     || |        /  /
      `r-._||/   __   /  /
  __,-<_     )`-/  `./  /
 '  \   `---'   \   /  /
     |           |./  /
     /           //  /
 \_/' \         |/  /
  |    |   _,^-'/  /
  |    , ``  (\/  /_
   \,.->._    \X-=/^
   (  /   `-._//^`
    `Y-.____(__}
     |     {__)
           ()`
EOF
echo "Please only use this to assist with reading logs $(tput sgr 0)"
echo "$(tput setaf 1)This is not a replacement $(tput sgr 0) \n"
echo "${newLog} will be saved to ${fileLoc}...\n"
daysFound=`egrep '^[^ ]+ (0[89]|1[0-9]|2[012]):' "${logFile}" | awk '{print $1}' | sort -u | wc -l | sed 's/ //g'`
echo "\n $daysFound days are found in the log...\n"
read -p "How many days would you like to search? " nDays
# check to validate the search for days
while [ "$nDays" -gt "$daysFound" ]; do
    read -p "Please enter $daysFound or less: " nDays
    done
    pastDays=($(egrep '^[^ ]+ (0[89]|1[0-9]|2[012]):' "${logFile}" | awk '{print $1}' | sort -u | tail -$nDays | tr '\n' ' ' ))
#Move old FilteredLog
if [ -f $sortedLog ]; then
    cat ${sortedLog} >> ${sortedLog}.old
    echo "" > ${sortedLog}
fi
##Funcations
#Create Unable to create Push CSV
function blankPush() {
    uuidCount=`grep 'Unable to create push' $sortedLog | wc -l`
    if [ $uuidCount -gt 0 ]; then
        uuidCount=`grep ${pastDays[$COUNTER]} "${logFile}" | grep 'Unable to create push' | wc -l`
        echo "${uuidCount} unique Blank pushes not created" >> $sortedLog
    fi
    if [ "$saveBlankPushToCSV" == "Yes" ]; then
            if [ "$bpcount" -eq "0" ]; then
                echo "ID,Type,Name" > $sortedUUID
            fi
            cat $sortedLog | grep 'Unable to create push' | sed 's/.*notification\ for\ device://g;s/\[//g;s/,//g;s/\]//g;s/.\ A.*//g;s/=//g;s/ID//g;s/Name//g' | awk '{print $2 "," $1 "," $3 ","}' | sort -u >> $sortedUUID
        fi
    sed -i '' '/Unable to create push/d' $sortedLog
    let bpcount=bpcount+1
}
#Clear out DuplicateBundleIDs if they exist
function duplicateBundleID() {
    duplicateBundleIDCount=`grep "Duplicate bundle ID" $sortedLog | wc -l`
    if [ "$duplicateBundleIDCount" -gt "0" ]; then
        duplicateBundleIDCount=`grep ${pastDays[$COUNTER]} "${logFile}" | grep "Duplicate bundle ID" | wc -l`
        echo "${duplicateBundleIDCount} Duplicate Bundle ID\'s found in Log" >> $sortedLog
    fi
    sed -i '' '/Duplicate bundle ID/d' $sortedLog
}
#MDM 400 errors
function mdmReturn() {
    mdmReturnCount400=`grep "Error processing mdm request, returning 400" $sortedLog | wc -l`
    mdmReturnCount500=`grep "Error processing request*.*Returning 500" $sortedLog | wc -l`
    if [ $mdmReturnCount400 -gt 0 ]; then
        mdmReturnCount400=`grep ${pastDays[$COUNTER]} "${logFile}" | grep "Error processing mdm request, returning 400" | wc -l`
        echo "${mdmReturnCount400} MDM 400 Errors Found in Log" >> $sortedLog
        if [ "$saveMDMReturntoCSV" == "Yes" ]; then
            if [ $mdmcount = 0 ]; then
                echo "Error,Device/Action,CmdUUID" > $sortedMDMReturn
                let mdmcount=mdmcount+1
            fi
            cat $sortedLog | grep "Error processing mdm request, returning 400" | sed 's/.*Device://g;s/CommandUUID://g;s/,//g' | awk '{print "400," $1 "," $2 }'>> $sortedMDMReturn
        fi
    fi
    if [ $mdmReturnCount500 -gt 0 ]; then
        mdmReturnCount500=`grep ${pastDays[$COUNTER]} "${logFile}" | grep 'Error processing request*.*Returning 500' | wc -l`
        echo "${mdmReturnCount500} MDM 500 Errors Found in Log" >> $sortedLog
        if [ "$saveMDMReturntoCSV" == "Yes" ]; then
            if [ $mdmcount = 0 ]; then
                echo "Error,Device/Action,CmdUUID" > $sortedMDMReturn
                let mdmcount=mdmcount+1
            fi
            cat $sortedLog | grep "Error processing request*.*Returning 500" | sed 's/.*action://g;s/CmdUUID://g;s/SigVerified.*//g;s/,//g' | awk '{print "500," $1 "," $2 }'>> $sortedMDMReturn
        fi
    fi
    sed -i '' '/Error processing mdm request, returning 400/d' $sortedLog
    sed -i '' '/Error processing request*.*Returning 500/d' $sortedLog
}
#Loop to create the new Log file
COUNTER=0
while [  $COUNTER -lt $nDays ]; do
    echo "Writing ${pastDays[$COUNTER]}..."
    ## Reading and condensing the logs Errors, Warnings and version of the JSS
    errorUn=`grep ${pastDays[$COUNTER]} "${logFile}" | grep '\[ERROR' | awk '{ s = ""; for (i = 5; i <= NF; i++) s = s $i " "; print s }' | sort -u`
    errorUnCount=`grep ${pastDays[$COUNTER]} "${logFile}" | grep '\[ERROR' | wc -l`
    echo "Found ${errorUnCount} Errors for ${pastDays[$COUNTER]e}"
    warnUn=`grep ${pastDays[$COUNTER]} "${logFile}" | grep '\[WARN' | awk '{ s = ""; for (i = 6; i <= NF; i++) s = s $i " "; print s }' | sort -u`
    warnUnCount=`grep ${pastDays[$COUNTER]} "${logFile}" | grep '\[WARN' | wc -l`
    echo "Found ${warnUnCount} Warnings for ${pastDays[$COUNTER]}"
    jssVersion=`grep ${pastDays[$COUNTER]} "${logFile}" | grep -i "JSS Version" | tail -1 | awk '{print $12}'`
    echo "\n"
    ## Create the Filtered Log
    echo "\n" >> $sortedLog
    echo " Date: ${pastDays[$COUNTER]}, JSS Version: $jssVersion" >> $sortedLog
    echo "--------------------------------------------------------------- " >> $sortedLog
    echo "${errorUnCount} total Errors, Unique Errors Below" >> $sortedLog
    echo "----------------------------------------------------------------------------------------" >> $sortedLog
    echo "${errorUn} \n" >> $sortedLog
    echo "${warnUnCount} total Warnings, Unique Warnings Below" >> $sortedLog
    echo "----------------------------------------------------------------------------------------" >> $sortedLog
    echo "${warnUn} \n" >> $sortedLog
    echo "Summarized Error and Warning Messages" >> $sortedLog
    echo "----------------------------------------------------------------------------------------" >> $sortedLog
    duplicateBundleID
    blankPush
    mdmReturn
  let COUNTER=COUNTER+1
done
#cleanup
sed -i '' 's/\]\ \[/\[/g' $sortedLog
if [ "$bpcount" -gt "1" ]; then
    mv $uuidCSVFile ${uuidCSVFile}.old
    echo "ID,Type,Name" > $sortedUUID
    tail -n +2 ${uuidCSVFile}.old | sort -u >> $uuidCSVFile
    rm ${uuidCSVFile}.old
fi
#Post Parse Actions
echo "\n Additions post parse:" >> $sortedLog
echo "---------------------- " >> $sortedLog
if [ "$saveBlankPushToCSV" == "Yes" ]; then
 echo "Blank Push request submissons saved to ${uuidCSVFile}" >> $sortedLog
fi
if [ "$saveMDMReturntoCSV" == "Yes" ]; then
    echo "MDM 400/500 Unique errors saved to ${sortedMDMReturn}" >> $sortedLog
fi
#opening the new log file when the script is completed
open $sortedLog
