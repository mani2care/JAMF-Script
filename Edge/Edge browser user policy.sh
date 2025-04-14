#!/bin/bash
#
# Author: Manikandan
# Description: This script sets Microsoft Edge startup behavior by configuring the homepage and startup URLs.
#              It updates the Edge preferences plist file and sets full file permissions.
#              Intended for use on macOS systems with user-level access.
#
echo "Creating new Edge settings..."

# Apply Edge settings
defaults write "$HOME/Library/Preferences/com.microsoft.Edge" RestoreOnStartupURLs -array "https://insideplus.abb.com/start"
defaults write "$HOME/Library/Preferences/com.microsoft.Edge" RestoreOnStartup -int 4
sleep 5
echo "$HOME"
chmod -R 777 ~/Library/Preferences/com.microsoft.Edge.plist
echo "Done"
