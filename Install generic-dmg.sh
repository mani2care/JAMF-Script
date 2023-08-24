#!/bin/bash

downloadURL="$4"                # Static url or command that can be used to return a dynamic url
appFileName="$5"                # "Google Chrome.app"
versionComparisonKey="$6"       # CFBundleShortVersionString
commandToGetDownloadURL="$7"    # "true" or empty
log="/var/log/install-upgrade-app-in-dmg.log"

# This script is intended to be run to download a dmg containing a .app and either install
# the .app or update the .app if a newer one was downloaded.

##### Variables beyond this point are not intended to be modified #####
appName="${appFileName%.*}"
loggedInUser=$( echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
loggedInUID=$(/usr/bin/id -u "$loggedInUser" 2> /dev/null)
uuid=$(/usr/bin/uuidgen)
workDir="/private/tmp/$uuid"
newAppVersion=""
appInstalled="false"
mgmtAction="/Library/Application Support/JAMF/bin/Management Action.app/Contents/MacOS/Management Action"
declare -a processIDs

# Functions
function writelog () {
	if [[ -n "$1" ]]; then
		DATE=$(date +%Y-%m-%d\ %H:%M:%S)
		printf "%s\n" "$1"
		printf "%s\n" "$DATE  $1" >> "$log"
	else
		if test -t 0; then return; fi
        while IFS= read -r pipeData; do
			DATE=$(date +%Y-%m-%d\ %H:%M:%S)
			printf "%s\n" "$pipeData"
			printf "%s\n" "$DATE  $pipeData" >> "$log"
		done
	fi
}

function clean_up () {
    writelog "Cleaning up installation files..."
    /usr/bin/hdiutil detach "$device" -force &> /dev/null
    /bin/rm -Rf "$workDir"

    if [[ "$appInstalled" == "true" ]]; then
        writelog "Updating inventory in Jamf Pro..."
        /usr/local/bin/jamf recon
    fi
}

function download_installation_files () {
    # Download the webpage source with installer download links
    writelog "$appName Download URL: $downloadURL"
    writelog "Downloading the $appName installation files..."

    # Exit if there was an error with the curl
    if ! /usr/bin/curl -s -L -f "$downloadURL" -o "$workDir/installMedium.dmg" ; then
        writelog "Error while downloading the installation files; exiting."
        exit 4
    fi

    # If no DMG was found in the install files, bail out
    if [[ ! -e "$workDir/installMedium.dmg" ]]; then
        writelog "Failed to download the installation files; exiting."
        exit 5
    fi

    # Mount the DMG, and save its device
    device=$(/usr/bin/hdiutil attach -nobrowse "$workDir/installMedium.dmg" | /usr/bin/grep "/Volumes" | /usr/bin/awk '{ print $1 }')
    if [[ -z "$device" ]]; then
        writelog "Failed to mount the downloaded dmg; exiting."
        exit 6
    fi

    # Using the device, determine the mount point
    mountPoint=$(/usr/bin/hdiutil info | /usr/bin/grep "^$device" | /usr/bin/cut -f 3)

    # Find the app inside the DMG
    downloadedApp=$(/usr/bin/find "$mountPoint" -type d -iname "*$appFileName" -maxdepth 1 | /usr/bin/grep -v "^$mountPoint$")

    # If no app was found in the dmg, bail out
    if [[ -z "$downloadedApp" ]]; then
        writelog "Failed to find $appFileName in downloaded installation files; exiting."
        exit 7
    fi

    # Extract the version of the newly downloaded app
    newAppVersion=$(/usr/bin/defaults read "$downloadedApp/Contents/Info.plist" $versionComparisonKey)
}

function check_if_downloaded_version_is_newer () {
    local oldAppVersion
    oldAppVersion=$(/usr/bin/defaults read "/Applications/$appFileName/Contents/Info.plist" $versionComparisonKey)

    if [[ -z "$newAppVersion" ]]; then
        writelog "Could not determine version of the downloaded $appFileName; exiting."
        exit 8
    fi

    # Robust version compare function came from: https://stackoverflow.com/a/4025065/12075814
    version_compare () {
        writelog "Comparing downloaded version with installed version..."
        if [[ "$1" == "$2" ]]; then
            return 0
        fi
        local IFS=.
        # shellcheck disable=SC2206
        local i ver1=($1) ver2=($2)
        # fill empty fields in ver1 with zeros
        for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
            ver1[i]=0
        done
        for ((i=0; i<${#ver1[@]}; i++)); do
            if [[ -z ${ver2[i]} ]]; then
                # fill empty fields in ver2 with zeros
                ver2[i]=0
            fi
            if ((10#${ver1[i]} > 10#${ver2[i]})); then
                return 1
            fi
            if ((10#${ver1[i]} < 10#${ver2[i]})); then
                return 2
            fi
        done
        return 0
    }

    test_comparison () {
        version_compare "$1" "$2"
        case $? in
            0) op='=';;
            1) op='>';;
            2) op='<';;
        esac
        writelog "Downloaded version ($1) $op Installed Version ($2)"
        if [[ "$op" != "$3" ]]; then
            writelog "Downloaded version IS NOT newer."
            return 1
        else
            writelog "Downloaded version IS newer."
            return 0
        fi
        
    }

    test_comparison "$newAppVersion" "$oldAppVersion" '>'

    return "$?"
}

function install_app () {
    writelog "Removing $appName..."
    /bin/rm -Rf "/Applications/$appFileName"
    writelog "Installing $appName..."
    /bin/cp -pR "$downloadedApp" /Applications/

    if [[ -e "/Applications/$appFileName" ]]; then
        writelog "$appName installed successfully."
        appInstalled="true"
    else
        writelog "$appName installation failed; exiting."
        exit 9
    fi
}

function notify_user () {
    local counter iconPath title jamfHelper description iconName deferButton continueButton result buttonClicked
    
    counter="15"
    title="IT Notification - Update $appName" 
    jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
    deferButton="Later"
    continueButton="Update"
    description="$appName needs to be closed so it can be updated, please click \"$continueButton\" to close the application and update now or choose \"$deferButton\" if you are unable to update now."
    iconName=$(/usr/bin/defaults read "$downloadedApp/Contents/Info.plist" CFBundleIconFile)

    # Sometimes the app icon specified in Info.plist is like AppIcon.icns, and sometimes like AppIcon, so account for both
    if [[ "$iconName" == *.icns ]]; then
        iconPath="$downloadedApp/Contents/Resources/$iconName"
    else
        iconPath="$downloadedApp/Contents/Resources/$iconName.icns"
    fi

    result=$(/bin/launchctl asuser "$loggedInUID" "$jamfHelper" "$jamfHelper" -windowType "utility" -title "$title" -alignDescription natural -description "$description" -icon "$iconPath" -button1 "$continueButton" -button2 "$deferButton")
    buttonClicked="${result:$i-1}"

    # User clicked the button to continue
    if [[ "$buttonClicked" == "0" ]]; then
        writelog "$loggedInUser chose to continue, killing $appName processes..."

        # Populate array with the app's process IDs and kill them if there are more than 1
        processIDs=(); while IFS='' read -ra line; do processIDs+=("$line"); done < <(pgrep -x "$processName")
        [[ "${#processIDs[@]}" -ge "1" ]] && kill -9 "${processIDs[@]}"
        
        # If there are still active processes for the app, attempt to kill them every two seconds for 30 seconds
        while [[ "${#processIDs[@]}" -ge "1" ]] && [[ $counter -gt "0" ]]; do
            /bin/sleep 2
            processIDs=(); while IFS='' read -ra line; do processIDs+=("$line"); done < <(pgrep -x "$processName")
            [[ "${#processIDs[@]}" -ge "1" ]] && kill -9 "${processIDs[@]}"
            ((counter--))
        done

        # If the processes are killed - install, otherwise exit
        if [[ "${#processIDs[@]}" -eq "0" ]]; then
            install_app
            writelog "Relaunching $appName for $loggedInUser."
            /bin/launchctl asuser "$loggedInUID" open "/Applications/$appFileName"
        else
            writelog "Could not kill $appName processes, exiting."
            exit 11
        fi

    # User clicked the defer button
    elif [[ "$buttonClicked" == "2" ]]; then
        writelog "$loggedInUser chose to postpone."
        exit 0

    # Something else occured
    else
        writelog "Unknown jamfHelper error occured; exiting."
        exit 12
    fi
}

# Main logic
# Clean up our temporary files upon exiting at any time
trap "clean_up" EXIT

if [[ "$commandToGetDownloadURL" == "true" ]]; then
    writelog "Calculating Download URL from command."
    downloadURL="$(eval "$downloadURL")"
fi

# Look for missing required parameters and exit accordingly
if [[ -z "$downloadURL" ]] || [[ "$downloadURL" != http* ]]; then
    writelog "Parameter 4 is missing or malformed; exiting." && exit 1
fi
[[ -z "$appFileName" ]] && writelog "Parameter 5 is missing; exiting." && exit 2
[[ -z "$versionComparisonKey" ]] && writelog "Parameter 6 is missing; exiting." && exit 3

# Make our working directory with our unique UUID generated in the variables section
/bin/mkdir -p "$workDir"

# Download the installation files
download_installation_files

# Check if the app is installed
if [[ -e "/Applications/$appFileName" ]]; then
    writelog "$appName is installed; continuing."
    # If the installed version matches the downloaded version, bail out
    if ! check_if_downloaded_version_is_newer ; then
        writelog "The installed version of $appName is the latest version; exiting."
        exit 0
    else
        # The downloaded version is greater than the installed version, we need to update
        if [[ -z "$loggedInUser" ]]; then
            writelog "Nobody is logged in, performing unattended update..."
            install_app
        else
            writelog "$loggedInUser is logged in, determining the $appName process name..."

            # Extract the process name of the app from its Info.plist
            processName=$(/usr/bin/defaults read "/Applications/$appFileName/Contents/Info.plist" CFBundleExecutable)

            if [[ -z "$processName" ]]; then
                writelog "Could not determine process name of $appName; exiting."
                exit 10
            else
                writelog "Process name: $processName"
            fi

            writelog "Checking for running $appName processes..."

            processIDs=(); while IFS='' read -ra line; do processIDs+=("$line"); done < <(pgrep -x "$processName")
            if [[ "${#processIDs[@]}" -ge "1" ]]; then
                writelog "$appName is running, alerting $loggedInUser of pending update."
                notify_user
            else
                writelog "$appName is NOT running, installing..."
                install_app
            fi

            # The script would exit if the app was not installed, so inform the user via Notification Center
            /bin/launchctl asuser "$loggedInUID" "$mgmtAction" -title "$appName Updated" -message "$appName was successfully updated to version $newAppVersion."
        fi
    fi
else
    writelog "$appName is NOT installed, performing installation."
    install_app

    # The script would exit if the app was not installed, so inform the user via Notification Center
    /bin/launchctl asuser "$loggedInUID" "$mgmtAction" -title "$appName Installed" -message "$appName version $newAppVersion was successfully installed."
fi

exit 0
