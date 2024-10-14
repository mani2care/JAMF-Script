#!/bin/bash

# MindManagerSettings.sh -- Set License and accept EULA

#---Variables---#
currentuser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
echo "Logged in user: $currentuser"


#---LicenseKey and Settings---#
#su -l $currentuser -c "defaults -currentHost write com.mindjet.mindmanager.23 LicenseKey 'APxxxx-xxxx-xxxx-xxxx'"

#---Functions---#

apply_mindmanager_23_settings() {
    echo "Applying settings for MindManager 23..."
    su -l "$currentuser" -c "defaults -currentHost write com.mindjet.mindmanager.23 ShowEULA -int 0"
    su -l "$currentuser" -c "defaults -currentHost write com.mindjet.mindmanager.23 Edition -int 0"
    su -l "$currentuser" -c "defaults write /Users/$currentuser/Library/Preferences/com.mindjet.mindmanager.23 FirstLaunch -bool false"
    su -l "$currentuser" -c "defaults write /Users/$currentuser/Library/Preferences/com.mindjet.mindmanager.23 DeviceAutoUpdateDisabled -bool false"
    su -l "$currentuser" -c "defaults write /Users/$currentuser/Library/Preferences/com.mindjet.mindmanager.23 StartupDialogPolicy -int 3"
    su -l "$currentuser" -c "defaults write /Users/$currentuser/Library/Preferences/com.mindjet.mindmanager.23 NewDocumentOnStart -int 1"
    su -l "$currentuser" -c "defaults write /Users/$currentuser/Library/Preferences/com.mindjet.mindmanager.23 ShowCheckForUpdates -int 0"
    su -l "$currentuser" -c "defaults write /Users/$currentuser/Library/Preferences/com.mindjet.mindmanager.23 UpdateCheck -int 86400"
    su -l "$currentuser" -c "defaults write /Users/$currentuser/Library/Preferences/com.mindjet.mindmanager.23 EnableTracking -bool false"
	su -l "$currentuser" -c "defaults write /Users/$currentuser/Library/Preferences/com.mindjet.mindmanager.23 EnableCheckForProductNotifications -bool false"
}

apply_mindmanager_24_settings() {
    echo "Applying settings for MindManager 24..."
    rm -rf /Users/$currentuser/Library/Preferences/com.mindjet.mindmanager.23.plist
    su -l "$currentuser" -c "defaults -currentHost write com.mindjet.mindmanager.24 ShowEULA -int 0"
    su -l "$currentuser" -c "defaults -currentHost write com.mindjet.mindmanager.24 Edition -int 0"
    su -l "$currentuser" -c "defaults write /Users/$currentuser/Library/Preferences/com.mindjet.mindmanager.24 FirstLaunch -bool false"
    su -l "$currentuser" -c "defaults write /Users/$currentuser/Library/Preferences/com.mindjet.mindmanager.24 DeviceAutoUpdateDisabled -bool false"
    su -l "$currentuser" -c "defaults write /Users/$currentuser/Library/Preferences/com.mindjet.mindmanager.24 StartupDialogPolicy -int 3"
    su -l "$currentuser" -c "defaults write /Users/$currentuser/Library/Preferences/com.mindjet.mindmanager.24 NewDocumentOnStart -int 1"
    su -l "$currentuser" -c "defaults write /Users/$currentuser/Library/Preferences/com.mindjet.mindmanager.24 ShowCheckForUpdates -int 0"
    su -l "$currentuser" -c "defaults write /Users/$currentuser/Library/Preferences/com.mindjet.mindmanager.24 UpdateCheck -int 86400"
    su -l "$currentuser" -c "defaults write /Users/$currentuser/Library/Preferences/com.mindjet.mindmanager.24 EnableTracking -bool false"
    su -l "$currentuser" -c "defaults write /Users/$currentuser/Library/Preferences/com.mindjet.mindmanager.24 EnableCheckForProductNotifications -bool false"
}


#---Check MindManager version from Info.plist---#

plist_path="/Applications/MindManager.app/Contents/Info.plist"

if [ -f "$plist_path" ]; then
    version=$(defaults read "$plist_path" CFBundleShortVersionString)
    echo "Detected MindManager version: $version"

    if [[ $version == 23.* ]]; then
        apply_mindmanager_23_settings
    elif [[ $version == 24.* ]]; then
        apply_mindmanager_24_settings
    else
        echo "Installed MindManager version is not supported."
    fi
else
    echo "MindManager is not installed."
fi

echo "Settings have been applied successfully."
