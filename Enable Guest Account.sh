#!/bin/sh

###
#
#            Name:  Enable Guest Account.sh
#     Description:  Enables guest account.

########## main process ##########

# Enable guest account.
/usr/bin/defaults write "/Library/Preferences/com.apple.loginwindow" GuestEnabled -bool TRUE
echo "Enabled guest account."



exit 0
