#!/bin/bash

# Loop through each user directory in /Users
loggedInUser=$(stat -f "%Su" /dev/console)
echo "loggedInUser=$loggedInUser"

USER_DIR=$(dscl . -read /Users/$loggedInUser NFSHomeDirectory | awk '{print $2}')
echo "USER_DIR=$USER_DIR"

# Get the username from the directory path
CURRENT_USER=$(dscl . -read /Users/$loggedInUser NFSHomeDirectory | awk '{print $2}' | xargs basename)
echo "CURRENT_USER=$CURRENT_USER"
        
# Read the current setting for AppleShowAllExtensions
/usr/bin/sudo -u "$loggedInUser" /usr/bin/defaults read "$USER_DIR/Library/Preferences/.GlobalPreferences" AppleShowAllExtensions 2>/dev/null
        
# Write the new setting for AppleShowAllExtensions
/usr/bin/sudo -u "$loggedInUser" /usr/bin/defaults write "$USER_DIR/Library/Preferences/.GlobalPreferences" AppleShowAllExtensions -bool true
