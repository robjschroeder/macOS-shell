loggedInUser=$( ls -l /dev/console | awk '{print $3}' )

rm -f -r "/Users/$loggedInUser/Library/Keychains/"*
shutdown -r now
exit