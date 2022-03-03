#!/bin/sh

#
# Quick and dirty, install all updates and restart
# using the softwareupdate binary
# @robjschroeder
#

/usr/sbin/softwareupdate --install --all --restart
