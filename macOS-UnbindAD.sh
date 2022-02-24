#!/bin/bash

# This script will unbind the mac
# from AD. A valid username and 
# password is NOT needed
#
# Updated: 2.23.2022 @ Robjschroeder
#
# Unbind with dsconfigad
dsconfigad -force -remove -u johndoe -p nopasswordhere

exit 0
