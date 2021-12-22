#!/bin/sh

####################################################################################################
#
# Sophos Endpoint Installation
#
####################################################################################################
#
# DESCRIPTION
#
# Installs Sophos Endpoint
#
####################################################################################################
# 
#
# Sophos Endpoint Installation Script

# Changing permissions on the Sophos Installer
sudo chmod a+x /private/tmp/SophosInstall/Sophos\ Installer.app/Contents/MacOS/Sophos\ Installer
sudo chmod a+x /private/tmp/SophosInstall/Sophos\ Installer.app/Contents/MacOS/tools/com.sophos.bootstrap.helper

# Run the installer
/private/tmp/SophosInstall/Sophos\ Installer.app/Contents/MacOS/Sophos\ Installer --install

####################################################################################################