#!/bin/sh

softwareUpdate --reset-ignored
softwareUpdate --fetch-full-installer --full-installer-version 10.15.7
/Applications/Install\ macOS\ Catalina.app/Contents/Resources/startosinstall --agreetolicense --forcequitapps