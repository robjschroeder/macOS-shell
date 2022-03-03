#!/bin/sh

# macOS Catalina Clean Install Script
# Script will download macOS Catalina,
# then run the installer with --eraseinstall
# @robjschroeder

# Reset any ignored updates
softwareUpdate --reset-ignored
# Fetch the latest macOS installer
softwareUpdate --fetch-full-installer
# Erase and Install
/Applications/Install\ macOS\ Catalina.app/Contents/Resources/startosinstall --eraseinstall --agreetolicense --forcequitapps --newvolumename "MacHD"
