#!/bin/sh

softwareUpdate --reset-ignored
softwareUpdate --fetch-full-installer
/Applications/Install\ macOS\ Catalina.app/Contents/Resources/startosinstall --eraseinstall --agreetolicense --forcequitapps --newvolumename "MacHD"