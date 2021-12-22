#!/bin/bash

# Get the current User
User=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`

/System/Library/CoreServices/ManagedClient.app/Contents/Resources/createmobileaccount -n $User