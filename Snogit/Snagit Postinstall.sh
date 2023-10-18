#!/bin/sh

loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

# Default Setting for Snagit - https://support.techsmith.com/hc/en-us/articles/115007344888-Enterprise-Install-Guidelines-for-Snagit-on-MacOS
defaults write "/Users/$loggedInUser/Library/Preferences/com.TechSmith.Snagit2023" RestrictedOutputs -array com.techsmith.shareplugin.Screencast2022 com.techsmith.shareplugin.QuickShare com.techsmith.shareplugin.Screencast com.techsmith.shareplugin.Knowmia com.techsmith.shareplugin.PanoptoPlugin com.techsmith.shareplugin.GoogleDrive com.techsmith.shareplugin.Slack com.techsmith.shareplugin.YouTube com.techsmith.shareplugin.Dropbox com.techsmith.shareplugin.FTP com.techsmith.shareplugin.FileSystem com.techsmith.shareplugin.Email com.techsmith.shareplugin.iWorkPages com.techsmith.shareplugin.iWorkKeynote com.techsmith.shareplugin.Program com.techsmith.shareplugin.iWorkNumbers com.techsmith.shareplugin.Box
defaults write "/Users/$loggedInUser/Library/Preferences/com.TechSmith.Snagit2023" DisableProductLogin -bool YES
defaults write "/Users/$loggedInUser/Library/Preferences/com.TechSmith.Snagit2023" HideRegistrationKey -bool YES
defaults write "/Users/$loggedInUser/Library/Preferences/com.TechSmith.Snagit2023" DisableCheckForUpdates -bool YES
defaults write "/Users/$loggedInUser/Library/Preferences/com.TechSmith.Snagit2023" DisableTracking -bool YES

# Fixing the plist permissions
chown "${loggedInUser}":staff "/Users/$loggedInUser/Library/Preferences/com.TechSmith.Snagit2023.plist"
chmod 600 "/Users/$loggedInUser/Library/Preferences/com.TechSmith.Snagit2023.plist"


# Get the process IDs of the application
app_pids=($(pgrep -f "/Applications/Snagit 2023"))
    
    # Check if there are any running processes
    if [ ${#app_pids[@]} -gt 0 ]; then
        # Terminate all running processes forcefully
        for pid in "${app_pids[@]}"; do
            kill -9 "$pid"
            echo "The application has been forcefully terminated =$pid"
        done
    fi
exit 0		## Success
exit 1		## Failure
