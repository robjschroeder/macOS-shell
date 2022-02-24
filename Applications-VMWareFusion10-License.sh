#!/bin/bash

# This script will serialize VMWare
# Fusion 10. Add valid serial number
#
# Updated: 2.23.2022 @ Robjschroeder
#
# Variables
serial="serialNumber"

export serial=$serial
/Applications/VMware\ Fusion.app/Contents/Library/Initialize\ VMware\ Fusion.tool set "" "" ${serial}
