#!/bin/bash

# Get GB size of /Users
du -h -d 0 /Users | awk '{print $1}'

exit 0