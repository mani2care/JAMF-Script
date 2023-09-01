#!/bin/bash
​
#set -x
​
swiftDialogAppPath="/Library/Application Support/Dialog/Dialog.app"
swiftDialogPath="/usr/local/bin/dialog"
companyLogo="/Library/Company/Images/Companylogo.png"
suScreenshot1="/Library/Company/Images/Software_Update1.png"
suScreenshot2="/Library/Company/Images/Software_Update2.png"
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
​
if [[ ! -e "$swiftDialogAppPath" ]] || [[ ! -e "$swiftDialogPath" ]]; then
	/bin/echo "$(date): swiftDialog not found. Installing swiftDialog."
	/usr/local/bin/jamf policy -event swiftDialogInstall -forceNoRecon -randomDelaySeconds 0
else
	/bin/echo "$(date): swiftDialog is already installed."
fi
​
if [[ ! -f "$companyLogo" ]] || [[ ! -f "$suScreenshot1" ]] || [[ ! -f "$suScreenshot2" ]]; then
	/bin/echo "$(date): Graphical assets not found.  Installing..."
	/usr/local/bin/jamf policy -event softwareupdatescreenshots -forceNoRecon -randomDelaySeconds 0
else
	/bin/echo "$(date): Graphical assets are already installed."
fi
​
# get the currently logged in user
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
​
# global check if there is a user logged in
if [ -z "$currentUser" -o "$currentUser" = "loginwindow" ]; then
  echo "no user logged in, cannot proceed"
  exit 1
fi
# now we know a user is logged in
​
# get the current user's UID
uid=$(id -u "$currentUser")
​
# convenience function to run a command as the current user
# usage:
#   runAsUser command arguments...
runAsUser() {  
  if [ "$currentUser" != "loginwindow" ]; then
    launchctl asuser "$uid" sudo -u "$currentUser" "$@"
  else
    echo "no user logged in"
    # uncomment the exit command
    # to make the function exit with an error when no user is logged in
    # exit 1
  fi
}
​
dialogOptions=(
	--moveable --width 800 --height 600
	--button1text Close --timer 1800 --hidetimerbar
	--icon "$companyLogo"
	--image "$suScreenshot1"
	--image "$suScreenshot2"
	--messagefont size=14
)
​
dialogContent=(
	--title "Applying Software Updates Manually"
	--infobox "Due to changes in macOS Monterey, Apple software updates must be applied manually at this time.\n\n Software Update will automatically open in a moment; if it does not, go to the Apple Menu, System Preferences, and click on **Software Update**.\n\n Follow the instructions in this dialog to apply available updates."
)
​
if [[ ! -e "$swiftDialogAppPath" ]] || [[ ! -e "$swiftDialogPath" ]]; then
jamfHelperDialog="Due to changes in macOS Monterey, Apple software updates must be applied manually at this time.
​
Software Update will automatically open in a moment; if it does not, go to the Apple Menu, System Preferences, and click on Software Update.
​
***Save your work before proceeding! Do NOT attempt to upgrade to macOS Ventura!***
​
Look for \"Another update is available\" or \"Other updates are available\" in the Software Update window, and click the \"More Info...\" link underneath.
​
Apply available updates for Monterey, Safari, etc. that appear in the secondary dialog box by clicking the \"Install Now\" button.
​
(You may not see any updates available if your Mac is already on macOS 12.6.7 or 12.6.8.)"
​
nohup "$jamfHelper" -windowType utility \
	-icon "$companyLogo" \
	-heading "" \
	-description "$jamfHelperDialog" \
	-button1 "OK" \
	-defaultButton 1 > /dev/null 2>&1 & disown
​
else
	"$swiftDialogPath" "${dialogOptions[@]}" "${dialogContent[@]}" & sleep 0.5
fi
​
sleep 8
​
runAsUser open "x-apple.systempreferences:com.apple.preferences.softwareupdate"
