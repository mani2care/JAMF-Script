#!/bin/bash
#
# Author: Manikandan
# Description: This script setsCHrome startup behavior by configuring the homepage and startup URLs.
#              It updates the Edge preferences plist file and sets full file permissions.
#              Intended for use on macOS systems with user-level access.
#
echo "Creating new Chrome settings..."

# Apply Chrome settings

defaults write "$HOME/Library/Preferences/com.google.Chrome" RestoreOnStartupURLs -array "https://insideplus.abb.com/start"
defaults write "$HOME/Library/Preferences/com.google.Chrome" RestoreOnStartup -int 4

sleep 5
chmod -R 777 ~/Library/Preferences/com.google.Chrome.plist
echo "Done"
