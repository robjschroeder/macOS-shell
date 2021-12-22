#!/bin/bash

# https://www.jamf.com/jamf-nation/discussions/30751/api-script-for-ipad-restart

jssURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed s'/.$//')

apiUser="user"
apiPass='password'
deviceID="167"

data="<mobile_device_command><general><command>RestartDevice</command></general><mobile_devices><mobile_device><id>${deviceID}</id></mobile_device></mobile_devices></mobile_device_command>"

echo "Attempting to send a RestartDevice command to Mobile Device with ID: $deviceID"
curl -ksu "$apiUser:$apiPass" -H "Content-Type: text/xml" "$jssURL/JSSResource/mobiledevicecommands/command" -d $data -X POST

exit 0