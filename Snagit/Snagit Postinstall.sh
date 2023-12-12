#!/bin/sh

loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

# Default Setting for Snagit - https://support.techsmith.com/hc/en-us/articles/115007344888-Enterprise-Install-Guidelines-for-Snagit-on-MacOS
defaults write "/Users/$loggedInUser/Library/Preferences/com.TechSmith.Snagit2024" RestrictedOutputs -array com.techsmith.shareplugin.Screencast2022 com.techsmith.shareplugin.QuickShare com.techsmith.shareplugin.Screencast com.techsmith.shareplugin.Knowmia com.techsmith.shareplugin.PanoptoPlugin com.techsmith.shareplugin.GoogleDrive com.techsmith.shareplugin.Slack com.techsmith.shareplugin.YouTube com.techsmith.shareplugin.Dropbox com.techsmith.shareplugin.FTP com.techsmith.shareplugin.FileSystem com.techsmith.shareplugin.Email com.techsmith.shareplugin.iWorkPages com.techsmith.shareplugin.iWorkKeynote com.techsmith.shareplugin.Program com.techsmith.shareplugin.iWorkNumbers com.techsmith.shareplugin.Box
defaults write "/Users/$loggedInUser/Library/Preferences/com.TechSmith.Snagit2024" DisableProductLogin -bool YES
defaults write "/Users/$loggedInUser/Library/Preferences/com.TechSmith.Snagit2024" HideRegistrationKey -bool YES
defaults write "/Users/$loggedInUser/Library/Preferences/com.TechSmith.Snagit2024" DisableCheckForUpdates -bool YES
defaults write "/Users/$loggedInUser/Library/Preferences/com.TechSmith.Snagit2024" DisableTracking -bool YES

#Theam deployment 

# Define folder and file paths
folder_path=/Users/$loggedInUser/Library/Group\ Containers/7TQL462TU8.com.techsmith.snagit/Snagit\ 2024/Themes
file_path="$folder_path/ABB.snagtheme"
source_file=/Users/Shared/ABB.snagtheme

# Check if the folder exists
if [ -d "$folder_path" ]; then
    echo "Folder exists."
else
    # If the folder does not exist, create it
    mkdir -p "$folder_path"
    echo "Folder created."
fi
    # If the file does not exist, move it to the folder
    mv "$source_file" "$file_path"
    echo "File moved to the folder."

# Grant the app permission
/bin/chmod -R 777 "/Users/Shared/Snagit"
/bin/chmod a+x "/Users/Shared/TechSmith/Snagit/LicenseKey"
chmod -R 775 /Users/$loggedInUser/Library/Group\ Containers/7TQL462TU8.com.techsmith.snagit/Snagit\ 2024/

#Hide the licence key
chflags hidden /Users/Shared/TechSmith/Snagit/LicenseKey 

#remove the quarantine
xattr -dr com.apple.quarantine /Applications/Snagit\ 2024.app 

#Fixing the plist permissions
chown "${loggedInUser}":staff "/Users/$loggedInUser/Library/Preferences/com.TechSmith.Snagit2024.plist"
chmod 600 "/Users/$loggedInUser/Library/Preferences/com.TechSmith.Snagit2024.plist"

exit 0		## Success
exit 1		## Failure
