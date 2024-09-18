#!/bin/sh
#your activation key for the version Snagit 2024
regkey="your licence key go here"
if [ -n "$regkey" ]; then
  [[ ! -d "/Users/Shared/TechSmith/Snagit" ]] && /bin/mkdir -p "/Users/Shared/TechSmith/Snagit"
  /bin/echo "$regkey" > "/Users/Shared/TechSmith/Snagit/LicenseKey"
  /bin/echo "$regkey" > "/Users/Shared/TechSmith/Snagit/LicensePassive"
fi

# Get the logged-in user
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

# Use dscl to get the correct home directory for the logged-in user
home_dir=$(dscl . -read /Users/$loggedInUser NFSHomeDirectory | awk '{print $2}')

# Default Settings for Snagit
defaults write "$home_dir/Library/Preferences/com.TechSmith.Snagit2024.plist" RestrictedOutputs -array com.techsmith.shareplugin.MSTeams com.techsmith.shareplugin.Screencast2022 com.techsmith.shareplugin.QuickShare com.techsmith.shareplugin.Screencast com.techsmith.shareplugin.Knowmia com.techsmith.shareplugin.PanoptoPlugin com.techsmith.shareplugin.GoogleDrive com.techsmith.shareplugin.Slack com.techsmith.shareplugin.YouTube com.techsmith.shareplugin.Dropbox com.techsmith.shareplugin.FTP com.techsmith.shareplugin.FileSystem com.techsmith.shareplugin.Email com.techsmith.shareplugin.iWorkPages com.techsmith.shareplugin.iWorkKeynote com.techsmith.shareplugin.Program com.techsmith.shareplugin.iWorkNumbers com.techsmith.shareplugin.Box
defaults write "$home_dir/Library/Preferences/com.TechSmith.Snagit2024.plist" DisableProductLogin -bool YES
defaults write "$home_dir/Library/Preferences/com.TechSmith.Snagit2024.plist" HideRegistrationKey -bool YES
defaults write "$home_dir/Library/Preferences/com.TechSmith.Snagit2024.plist" DisableTracking -bool YES

# Theme Deployment

# Define folder and file paths
folder_path="$home_dir/Library/Group Containers/7TQL462TU8.com.techsmith.snagit/Snagit 2024/Themes"
file_path="$folder_path/ABB.snagtheme"
source_file="/Users/Shared/ABB.snagtheme"

# Check if the folder exists
if [ -d "$folder_path" ]; then
    echo "Folder exists."
else
    # If the folder does not exist, create it
    mkdir -p "$folder_path"
    echo "Folder created."
fi

# Move the theme file
mv "$source_file" "$file_path"
echo "File moved to the folder."

# Grant the app permission
chmod -R 777 "/Users/Shared/TechSmith"

licensePassiveFile="/Users/Shared/TechSmith/Snagit/LicensePassive"

# Check if LicensePassive file exists
if [ -f "$licensePassiveFile" ]; then
    chmod -R 777 "/Users/Shared/TechSmith/Snagit/LicensePassive"
    # Grant execute permission
    chmod a+x "$licensePassiveFile"
    # Hide the file
    chflags hidden "$licensePassiveFile"
    echo "LicensePassive file exists. Execute permission granted and file hidden."
else
    echo "LicensePassive file not found."
fi

# Fix permissions for Snagit folder and plist file
chmod -R 775 "$home_dir/Library/Group Containers/7TQL462TU8.com.techsmith.snagit/Snagit 2024/"
xattr -dr com.apple.quarantine /Applications/Snagit\ 2024.app 
chown "$loggedInUser":staff "$home_dir/Library/Preferences/com.TechSmith.Snagit2024.plist"
chmod 600 "$home_dir/Library/Preferences/com.TechSmith.Snagit2024.plist"

exit 0  ## Success
exit 1  ## Failure
