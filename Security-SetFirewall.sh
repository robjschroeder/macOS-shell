#!/bin/bash

####################################################################################################
# Script tested with the following software
####################################################################################################
# macOS 10.9.x, 10.10.x, 10.11.x, 10.12.x, 10.13.x, 10.14.x, 10.15.x, 11
# DEPNotify 1.1.2, 1.1.3
# JAMF Pro 10.6 - 10.9

####################################################################################################
# Usage
####################################################################################################
# Enables the local firewall in macOS
# Launches DEPNotify with the jamf and fullscreen flags and executes onboarding policy
# Removes DEPNotify and support files after enrollment

####################################################################################################
# User experience variables - Modify as needed)
####################################################################################################
APP_FIREWALL="/usr/libexec/ApplicationFirewall/socketfilterfw"

GLOBAL_STATE="$4" # Set this variable in JAMF Pro to On | Off
ALLOWED_SIGNED="$5" # Set this variable in JAMF Pro to On | Off
BLOCK_ALL="$6" # Set this variable in JAMF Pro to On | Off
LOGGING_MODE="$7" # Set this variable in JAMF Pro to On | Off
 
####################################################################################################
# Script Logic
####################################################################################################
# Enable the firewall
"$APP_FIREWALL" --setglobalstate "$GLOBAL_STATE"

# Allow signed apps traffic
"$APP_FIREWALL" --setallowsigned "$ALLOWED_SIGNED"

# Block all incoming connections
"$APP_FIREWALL" --setblockall "$BLOCK_ALL"

# Set logging mode to 
"$APP_FIREWALL" --setloggingmode "$LOGGING_MODE"

exit 0