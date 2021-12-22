#!/bin/bash

function ConfigureZoom () {

    echo "`date` Adding preferences for all users"

    #Preferences - UPDATE WITH YOUR OWN
    #defaults write /Library/Preferences/us.zoom.config.plist ZAutoJoinVoip -string YES
    defaults write /Library/Preferences/us.zoom.config.plist ZAutoSSOLogin -string YES
    defaults write /Library/Preferences/us.zoom.config.plist ZSSOHost -string domain.zoom.us
    defaults write /Library/Preferences/us.zoom.config.plist nogoogle  -string 1
    defaults write /Library/Preferences/us.zoom.config.plist nofacebook -string 1
    echo "`date` All preferences are now added"
    echo "`date` Installation is now complete"
    echo "`date` ========== Installation Ended =========="

}

function RemoveZoom () {

    # Remove and all related files if Zoom if installed
    echo "`date` Removing Zoom"
    if [[ -d '/Applications/zoom.us.app' ]]; then
        until [[ ! -d '/Applications/zoom.us.app' ]]; do
            rm -rf /Applications/zoom.us.app
        done
        echo "`date` Zoom was removed"
        echo "`date` Beginning installation of Zoom"
        InstallZoom
    fi

}

function InstallZoom () {

    # download and install the latest version
    until [[ -d '/Applications/zoom.us.app' ]]; do
        if [[ -e /tmp/ZoomInstallerIT.pkg ]]; then
            rm -rf /tmp/ZoomInstallerIT.pkg
        fi
        if [[ -d /tmp/_MACOSX ]]; then
            rm -rf /tmp/__MACOSX/
        fi
        if [[ -d /tmp/Zoom.app ]]; then
            rm -rf /tmp/Zoom.app
        fi
        echo "`date` Downloading Zoom"
        curl -L -o /tmp/ZoomInstallerIT.pkg "https://zoom.us/client/latest/ZoomInstallerIT.pkg" >/dev/null 2>&1
        echo "`date` Zoom Download complete"

        echo "`date` Downloading Zoom Outlook Plugin"
        curl -L -o /tmp/ZoomMacOutlookPlugin.pkg "https://zoom.us/client/latest/ZoomMacOutlookPlugin.pkg" >/dev/null 2>&1
        echo "`date` Zoom Outlook plugin download complete"
        cd /tmp/
        echo "`date` Installing Zoom"
        installer -pkg /tmp/ZoomInstallerIT.pkg -target /
        echo "`date` Installing Zoom Outlook Plugin"
        installer -pkg /tmp/ZoomMacOutlookPlugin.pkg -target /
        echo "`date` Editing permissions"
        chown -R root:wheel /Applications/zoom.us.app
        chmod -R 755 /Applications/zoom.us.app
        cd ~
        echo "`date` Removing temporary files"
        rm -rf /tmp/ZoomInstallerIT.pkg && rm -rf /tmp/ZoomMacOutlookPlugin.pkg && rm -rf /tmp/__MACOSX && rm -rf /tmp/zoom.us.app
        echo "`date` configuring Zoom"
        ConfigureZoom
    done
    echo "``date`` Zoom Installed"

}


function DetectZoom () {

    # Check to see whether Zoom is installed or not, if yes, remove it, then install latest, if no, then install latest.
    pgrep zoom >/dev/null
    if [[ $? = 0 ]]; then
        pkill zoom
    fi
    echo "`date` ========== Installation Started =========="
    echo "`date` Detecting if Zoom is installed or not"
    if [[ -d '/Applications/zoom.us.app' ]]; then
        echo "`date` Zoom was detected, will remove"
        RemoveZoom
    else
        echo "`date` Zoom was not detected, will install"
        InstallZoom
    fi

}

function LogZoom () {

    # Setup log files if logs do not exists, create it, otherwise start logging
    LogFile="/Library/Logs/Zoom_install.log"
    if [[ ! -e $LogFile ]]; then
        touch $LogFile && exec >> $LogFile
        echo "`date` ========== Log File Created =========="
    else
        exec >> $LogFile
    fi

}

LogZoom
DetectZoom

exit 0