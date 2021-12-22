#!/bin/sh

# Installs Western Voice App
# rjs41 3.10.2017
shareUser="shareuser"
sharePass="sharePWD"
server="server.domain.com"

mkdir /Users/Shared/Apple-Deploy
mount -t smbfs //$shareUser:$sharePass@$server/deploy /Users/Shared/Apple-Deploy/
cp -R /Users/Shared/Apple-Deploy/Kaseya-Apple/Apps/WesternVoice/Western\ Voice.app /Applications/
chmod -R 775 /Applications/Western\ Voice.app
umount /Users/Shared/Apple-Deploy
rmdir /Users/Shared/Apple-Deploy

# Done