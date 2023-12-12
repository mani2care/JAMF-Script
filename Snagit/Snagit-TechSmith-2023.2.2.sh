#!/bin/bash
#if you are using the dmg or installing directly from online then use this script
app_name="Snagit 2023"
app_path="/Applications/Snagit 2023.app" # Define the path to the application

#sudo tccutil reset All com.techsmith.snagit.capturehelper2023
#sudo tccutil reset All com.TechSmith.Snagit2023

#Default Setting for Snagit - https://support.techsmith.com/hc/en-us/articles/115007344888-Enterprise-Install-Guidelines-for-Snagit-on-MacOS
if [ -d "$app_path" ]; then

	echo "The Applications was found $app_name"

function applicationprocesskill() {
    # Get the process IDs of the application
    app_pids=($(pgrep -f "$app_path"))
    
    # Check if there are any running processes
    if [ ${#app_pids[@]} -gt 0 ]; then
        # Terminate all running processes forcefully
        for pid in "${app_pids[@]}"; do
            kill -9 "$pid"
            echo "The application has been forcefully terminated =$pid"
        done
    fi
}
applicationprocesskill 

	# Check if the "com.apple.quarantine" attribute exists on the application
		if xattr -p com.apple.quarantine "$app_path" &>/dev/null; then
		    # Remove the "com.apple.quarantine" attribute
		    xattr -r -d com.apple.quarantine "$app_path"
		    echo "Quarantine attribute removed from $app_path"
		else
		    echo "Quarantine attribute was not found on $app_path"
		fi

	# Define the desired Activation Key
	Activationkey="your licence key go here "

	# Define the path to the LicenseKey file
	LicenseKeyFile="/Users/Shared/TechSmith/Snagit/LicenseKey"

	echo "Step 1: Checking if LicenseKey file exists and its content is not equal to the Activation Key..."

		# Check if LicenseKey file exists and its content is not equal to the Activation Key
		if [[ -e "$LicenseKeyFile" && $(cat "$LicenseKeyFile") != "$Activationkey" ]]; then
		    # Remove the existing LicenseKey file
		    echo "Removing existing LicenseKey file..."
		    rm -f "$LicenseKeyFile"
		fi

	echo "Step 2: Creating or updating the LicenseKey file with the Activation Key..."
	# Create or update the LicenseKey file with the Activation Key
	echo "$Activationkey" > "$LicenseKeyFile"

	# Set permissions
	echo "Step 3: Setting permissions..."
	chmod -R 777 "/Users/Shared/TechSmith"
	chmod a+x "$LicenseKeyFile"

	echo "Step 3.1: Activation Key has been updated in '$LicenseKeyFile'."

	echo "Step 4: Updating Snagit preferences..."

	#defaults write com.TechSmith.Snagit2021.plist RestrictedOutputs -array com.techsmith.shareplugin.Screencast2022 com.techsmith.shareplugin.QuickShare com.techsmith.shareplugin.Screencast com.techsmith.shareplugin.Camtasia com.techsmith.shareplugin.Knowmia com.techsmith.shareplugin.PanoptoPlugin com.techsmith.shareplugin.GoogleDrive com.techsmith.shareplugin.Slack com.techsmith.shareplugin.YouTube com.techsmith.shareplugin.Dropbox com.techsmith.shareplugin.FTP com.techsmith.shareplugin.FileSystem com.techsmith.shareplugin.MSWord com.techsmith.shareplugin.MSPowerPoint com.techsmith.shareplugin.Email com.techsmith.shareplugin.iWorkPages com.techsmith.shareplugin.iWorkKeynote com.techsmith.shareplugin.Program com.techsmith.shareplugin.iWorkNumbers com.techsmith.shareplugin.MSExcel com.techsmith.shareplugin.Box
	 defaults write com.TechSmith.Snagit2021.plist RestrictedOutputs -array com.techsmith.shareplugin.Screencast2022 com.techsmith.shareplugin.QuickShare com.techsmith.shareplugin.Screencast com.techsmith.shareplugin.Knowmia com.techsmith.shareplugin.PanoptoPlugin com.techsmith.shareplugin.GoogleDrive com.techsmith.shareplugin.Slack com.techsmith.shareplugin.YouTube com.techsmith.shareplugin.Dropbox com.techsmith.shareplugin.FTP com.techsmith.shareplugin.FileSystem com.techsmith.shareplugin.Email com.techsmith.shareplugin.iWorkPages com.techsmith.shareplugin.iWorkKeynote com.techsmith.shareplugin.Program com.techsmith.shareplugin.iWorkNumbers com.techsmith.shareplugin.Box

	echo "Step 5: Disabling Sign In..."

	# Disable Sign In - This lets you turn off the TechSmith account and sign-in options.
	defaults write com.TechSmith.Snagit2023.plist DisableProductLogin -bool YES

	echo "Step 6: Hiding registration information..."

	# Hides references to the license key, registration info, and deactivation options.
	defaults write com.TechSmith.Snagit2023.plist HideRegistrationKey -bool YES

	echo "Step 7: Disabling check for updates..."

	# Hides the check for updates menu items, prefs, and ability to update.
	defaults write com.TechSmith.Snagit2023.plist DisableCheckForUpdates -bool YES

	echo "Step 8: Disabling analytics tracking..."

	# This lets you turn off the analytics tracking
	defaults write com.TechSmith.Snagit2023.plist DisableTracking -bool YES


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
		applicationprocesskill

	exit 0  ## Success
else
	echo "Application Not installed $app_name"
	#exit 1  ## Failure
fi
