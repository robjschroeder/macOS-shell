#!/bin/sh
#
#
#     Created by A.Hodgson
#      Date: 03/01/2019
#      Purpose: Sign Configuration profile
#  
#
######################################

#user
loggedInUser=$(/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }')

#create CSR
openssl req -out /Users/$loggedInUser/Downloads/CSR.csr -new -newkey rsa:2048 -nodes -keyout /Users/$loggedInUser/Downloads/.privateKey.key

#output instructions
echo ""
echo "A CSR has been placed in /Users/$loggedInUser/Downnloads/CSR.csr."
echo ""
echo "1 - Please 'Create Certificate from CSR' in Jamf Pro - Settings - Global Management - PKI - Management Certificate Template"
echo "2 - Copy/Paste the contents of the CSR into the box"
echo "3 - Select 'Web Server Certifcate' from the Certificate Type dropdown menu"
echo ""

#profileLocation
read -p "Please drag your downloaded cert (.pem file) into terminal: " pemCert

echo ""

#profileLocation
read -p "Please drag your unsigned profile into terminal: " unSignedProfile

#create profile
output=$(openssl smime -sign -signer "$pemCert" -inkey "/Users/$loggedInUser/Downloads/.privateKey.key" -nodetach -outform der -in "$unSignedProfile" -out "/Users/$loggedInUser/Downloads/signedProfile.mobileconfig")


#check that script was signed ok, otherwise output error
if [$output == ""]
then
	echo ""
	echo "Profile has been signed and output to /Users/$loggedInUser/Downloads/signedProfile.mobileconfig"
	#remove files created from workflow 
	[ -e $pemCert ] && rm -f $pemCert
	[ -e /Users/$loggedInUser/Downloads/CSR.csr ] && rm -f /Users/$loggedInUser/Downloads/CSR.csr
	[ -e /Users/$loggedInUser/Downloads/.privateKey.key ] && rm -f /Users/$loggedInUser/Downloads/.privateKey.key
	echo ""
	echo "Files created during workflow have been deleted."
	echo ""
	#exit script gracefully
	exit 0 
else
	echo ""
	echo "Something went wrong:"
	echo $output
	#remove files created from workflow 
	[ -e /Users/$loggedInUser/Downloads/signedProfile.mobileconfig ] && rm -f /Users/$loggedInUser/Downloads/signedProfile.mobileconfig
	[ -e $pemCert ] && rm -f $pemCert
	[ -e /Users/$loggedInUser/Downloads/CSR.csr ] && rm -f /Users/$loggedInUser/Downloads/CSR.csr
	[ -e /Users/$loggedInUser/Downloads/.privateKey.key ] && rm -f /Users/$loggedInUser/Downloads/.privateKey.key
	echo ""
	echo "Files created during workflow have been deleted."
	echo ""
	#exit script with an error
	exit 1 
fi