#!/bin/bash

####################################################################################################
#
# Setup Your Mac via swiftDialog
# https://snelson.us/setup-your-mac/
# https://github.com/dan-snelson/dialog-scripts/tree/main/Setup%20Your%20Mac
####################################################################################################
#
# HISTORY
#   
#  Thanks to Dan K. Snelson (@dan-snelson)rom Version 1.3.0, 09-Nov-2022, 
#  Script Parameter Changes:
#       - Parameter 4: `debug` mode enabled by default
#       - Parameter 7: Script Log Location
#       Embraced drastic speed improvements in swiftDialog v2
#       Caffeinated script (thanks, @grahampugh!)
#       Enhanced `wait` exiting logic
#       General script standardization
#   Modifier Manikandan (@mani2care) - Version-1 -1-Dec-2022
####################################################################################################



####################################################################################################
#
# Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Script Version & Jamf Pro Script Parameters
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptVersion="1.3.0"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/
debugMode="${4:-"false"}"            # [ true (default) | false ]
assetTagCapture="${5:-"false"}"     # [ true | false (default) ]
completionAction="${6:-"wait"}"     # [ number of seconds to sleep | wait (default) ]
scriptLog="${7:-"/var/tmp/org.churchofjesuschrist.log"}"

if [[ ${debugMode} == "true" ]]; then
    scriptVersion="Dialog: v$(dialog --version) • Setup Your Mac: v${scriptVersion}"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for an allowed "Completion Action" value (Parameter 6); defaults to "wait"
# Options: [ number of seconds to sleep | wait (default) ]
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

case "${completionAction}" in
    '' | *[!0-9]*   ) completionAction="wait" ;;
    *               ) completionAction="sleep ${completionAction}" ;;
esac

if [[ ${debugMode} == "true" ]]; then
    echo "Using \"${completionAction}\" as the Completion Action"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set Dialog path, Command Files, JAMF binary, log files and currently logged-in user
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogApp="/usr/local/bin/dialog"
welcomeCommandFile=$( mktemp /var/tmp/dialogWelcome.XXX )
setupYourMacCommandFile=$( mktemp /var/tmp/dialogSetupYourMac.XXX )
setupYourMacPolicyArrayIconPrefixUrl="https://euc-eme-002.abb.com:8443/icon?id="
failureCommandFile=$( mktemp /var/tmp/dialogFailure.XXX )
jamfBinary="/usr/local/bin/jamf"
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
loggedInUserFullname=$( id -F "${loggedInUser}" )
loggedInUserFirstname=$( echo "$loggedInUserFullname" | cut -d " " -f 1 )



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# APPS TO BE INSTALLED (Thanks, Obi-@smithjw!)
#
# For each configuration step, specify:
# - listitem: The text to be displayed in the list
# - icon: The hash of the icon to be displayed on the left
#   - See: https://rumble.com/v119x6y-harvesting-self-service-icons.html
# - progresstext: The text to be displayed below the progress bar 
# - trigger: The Jamf Pro Policy Custom Event Name
# - path: The filepath for validation
#
# shellcheck disable=1112
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

policy_array=('
{
    "steps": [
        {
            "listitem": "VLC",
            "icon": "153",
            "progresstext": "Uninstalling VLC ",
            "trigger_list": [
                {
                    "trigger": "vlcdelete",
                    "path": "/Applications/VLC.app"
                }
            ]
        },
        {
            "listitem": "Update Inventory",
            "icon": "125",
            "progresstext": "Updating the inventory sent to the Jamf Pro.",
            "trigger_list": [
                {
                    "trigger": "recon",
                    "path": "/Library/Application Support/JAMF/Jamf.app"
                }
            ]
        }
    ]
}
')



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Welcome / Asset Tag" Dialog Title, Message and Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

welcomeTitle="Hello ${loggedInUserFirstname}! Welcome to ABB"
welcomeMessage="To begin, please enter your Mac's **Asset Tag**, then click **Continue** to start applying Church settings to your new Mac.  \n\nOnce completed, the **Quit** button will be re-enabled and you'll be prompted to restart your Mac.  \n\nIf you need assistance, please contact the Help Desk: +1 (801) 555-1212."

appleInterfaceStyle=$( /usr/bin/defaults read /Users/"${loggedInUser}"/Library/Preferences/.GlobalPreferences.plist AppleInterfaceStyle 2>&1 )

if [[ "${appleInterfaceStyle}" == "Dark" ]]; then
    welcomeIcon="https://wallpapercave.com/dwp2x/MGxxFCB.jpg"
else
    welcomeIcon="https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/Apple_Computer_Logo_rainbow.svg/1028px-Apple_Computer_Logo_rainbow.svg.png?20201228132849"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Welcome / Asset Tag" Dialog Settings and Features
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogWelcomeCMD="$dialogApp \
--title \"$welcomeTitle\" \
--message \"$welcomeMessage\" \
--icon \"$welcomeIcon\" \
--iconsize 198 \
--button1text \"Continue\" \
--button2text \"Quit\" \
--button2disabled \
--infotext \"$scriptVersion\" \
--moveable \
--titlefont 'size=26' \
--messagefont 'size=16' \
--textfield \"Asset Tag\",required=true,prompt=\"Please enter your Mac's seven-digit Asset Tag\",regex='^(AP|IP)?[0-9]{7,}$',regexerror=\"Please enter (at least) seven digits for the Asset Tag, optionally preceed by either 'AP' or 'IP'. \" \
--quitkey k \
--commandfile \"$welcomeCommandFile\" "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Setup Your Mac" Dialog Title, Message, Overlay Icon and Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

title="Hello ${loggedInUserFirstname}!"
message="ABB Administrator desired to revoke all the ABB owned softwares \n\n Please wait while the following apps are uninstalling..."
overlayicon=$( defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_app_path )

# Set initial icon based on whether the Mac is a desktop or laptop
if system_profiler SPPowerDataType | grep -q "Battery Power"; then
  icon="SF=laptopcomputer.and.arrow.down,weight=semibold,colour1=#ef9d51,colour2=#ef7951"
else
  icon="SF=desktopcomputer.and.arrow.down,weight=semibold,colour1=#ef9d51,colour2=#ef7951"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Setup Your Mac" Dialog Settings and Features
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogSetupYourMacCMD="$dialogApp \
--title \"$title\" \
--message \"$message\" \
--icon \"$icon\" \
--progress \
--progresstext \"Initializing configuration …\" \
--button1text \"Quit\" \
--button1disabled \
--infotext \"$scriptVersion\" \
--titlefont 'size=28' \
--messagefont 'size=14' \
--height '40%' \
--position 'centre' \
--moveable \
--overlayicon \"$overlayicon\" \
--quitkey k \
--commandfile \"$setupYourMacCommandFile\" "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Failure" Dialog Title, Message and Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

failureTitle="Failure Detected"
failureMessage="Placeholder message; update in the finalise function"
failureIcon="SF=xmark.circle.fill,weight=bold,colour1=#BB1717,colour2=#F31F1F"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Failure" Dialog Settings and Features
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogFailureCMD="$dialogApp \
--moveable \
--title \"$failureTitle\" \
--message \"$failureMessage\" \
--icon \"$failureIcon\" \
--iconsize 125 \
--width 625 \
--height 300 \
--position topright \
--button1text \"Close\" \
--infotext \"$scriptVersion\" \
--titlefont 'size=22' \
--messagefont 'size=14' \
--overlayicon \"$overlayicon\" \
--commandfile \"$failureCommandFile\" "



#------------------------------- Edits below this line are optional -------------------------------#



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Script Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# JAMF Display Message (for fallback in case swiftDialog fails to install)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function jamfDisplayMessage() {
    updateScriptLog "Jamf Display Message: ${1}"
    /usr/local/jamf/bin/jamf displayMessage -message "${1}" &
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for / install swiftDialog (Thanks big bunches, @acodega!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogCheck() {

  # Get the URL of the latest PKG From the Dialog GitHub repo
  dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

  # Expected Team ID of the downloaded PKG
  expectedDialogTeamID="PWA5E9TQ59"

  # Check for Dialog and install if not found
  if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then

    updateScriptLog "Dialog not found. Installing..."

    # Create temporary working directory
    workDirectory=$( /usr/bin/basename "$0" )
    tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )

    # Download the installer package
    /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"

    # Verify the download
    teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')

    # Install the package if Team ID validates
    if [ "$expectedDialogTeamID" = "$teamID" ] || [ "$expectedDialogTeamID" = "" ]; then
 
      /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /

    else

      jamfDisplayMessage "Dialog Team ID verification failed."
      exit 1

    fi
 
    # Remove the temporary working directory when done
    /bin/rm -Rf "$tempDirectory"  

  else

    updateScriptLog "swiftDialog version $(dialog --version) found; proceeding..."

  fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Execute a "Welcome / Asset Tag" Dialog command
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogUpdateWelcome(){
    updateScriptLog "WELCOME DIALOG: $1"
    echo "$1" >> "$welcomeCommandFile"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Execute a "Setup Your Mac" Dialog command
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogUpdateSetupYourMac() {
    updateScriptLog "SETUP YOUR MAC DIALOG: $1"
    echo "$1" >> "$setupYourMacCommandFile"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Execute a "Failure" Dialog command
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogUpdateFailure(){
    updateScriptLog "FAILURE DIALOG: $1"
    echo "$1" >> "$failureCommandFile"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Finalise app installations
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function finalise(){

    if [[ "${jamfProPolicyTriggerFailure}" == "failed" ]]; then

        killProcess "caffeinate"
        dialogUpdateSetupYourMac "icon: SF=xmark.circle.fill,weight=bold,colour1=#BB1717,colour2=#F31F1F"
        dialogUpdateSetupYourMac "progresstext: Failures detected. Please click Continue for troubleshooting information."
        dialogUpdateSetupYourMac "button1text: Continue …"
        dialogUpdateSetupYourMac "button1: enable"
        dialogUpdateSetupYourMac "progress: complete"
        updateScriptLog "Jamf Pro Policy Name Failures: ${jamfProPolicyPolicyNameFailures}"
        eval "${completionAction}"
        dialogUpdateSetupYourMac "quit:"
        eval "${dialogFailureCMD}" & sleep 0.3
        if [[ ${debugMode} == "true" ]]; then
            dialogUpdateFailure "title: DEBUG MODE | $failureTitle"
        fi
        dialogUpdateFailure "message: A failure has been detected, ${loggedInUserFirstname}.  \n\nPlease complete the following steps:\n1. Reboot and login to your Mac  \n2. Find the application and delete manually.  \n\nThe following failed to Delete.  \n${jamfProPolicyPolicyNameFailures}  \n\n\n\nIf you need assistance, please contact the ABB Help Desk. "
        dialogUpdateFailure "icon: SF=xmark.circle.fill,weight=bold,colour1=#BB1717,colour2=#F31F1F"
        eval "${completionAction}"
        dialogUpdateFailure "quit:"
        quitScript "1"

    else

        dialogUpdateSetupYourMac "icon: SF=checkmark.circle.fill,weight=bold,colour1=#00ff44,colour2=#075c1e"
        dialogUpdateSetupYourMac "progresstext: Uninstallation completed please select CA Certificate and click '-' to remove. Restart your MAC in order to complete the process."
        dialogUpdateSetupYourMac "progress: complete"
        dialogUpdateSetupYourMac "button1text: Quit"
        dialogUpdateSetupYourMac "button1: enable"
        $jamfBinary jamf removeframework 
        sleep 3
        open /System/Library/PreferencePanes/Profiles.prefPane
        open x-apple.systempreferences:com.apple.SystemProfiler.AboutExtension
        if [[ "${completionAction}" == "wait" ]]; then
            wait "${dialogProcessID}" # Comment-out this line to NOT require user-interaction for successful completions
        else
            eval "${completionAction}"
        fi
        quitScript "0"   

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse JSON via osascript and JavaScript
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function get_json_value() {
    JSON="$1" osascript -l 'JavaScript' \
        -e 'const env = $.NSProcessInfo.processInfo.environment.objectForKey("JSON").js' \
        -e "JSON.parse(env).$2"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# smithjw's sweet function to execute Jamf Pro Policy Custom Events
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function run_jamf_trigger() {
    trigger="$1"
    if [[ "$debugMode" = true ]]; then
        updateScriptLog "SETUP YOUR MAC DIALOG: DEBUG MODE: $jamfBinary policy -event $trigger"
        sleep 2
    elif [[ "$trigger" == "recon" ]]; then
        if [[ ${assetTagCapture} == "true" ]]; then
            updateScriptLog "SETUP YOUR MAC DIALOG: RUNNING: $jamfBinary recon -assetTag ${assetTag}"
            "$jamfBinary" recon -assetTag "${assetTag}"
        else
            updateScriptLog "SETUP YOUR MAC DIALOG: RUNNING: $jamfBinary recon"
            "$jamfBinary" recon
        fi
    else
        updateScriptLog "SETUP YOUR MAC DIALOG: RUNNING: $jamfBinary policy -event $trigger"
        "$jamfBinary" policy -event "$trigger"
    fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Kill a specified process (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function killProcess() {

    process="$1"
    if process_pid=$( pgrep -a "${process}" 2>/dev/null ) ; then
        updateScriptLog "Attempting to terminate the '$process' process …"
        updateScriptLog "(Termination message indicates success.)"
        kill "$process_pid" 2> /dev/null
        if pgrep -a "$process" >/dev/null ; then
            updateScriptLog "ERROR: '$process' could not be terminated."
        fi
    fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Quit Script (thanks, @bartreadon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function quitScript() {

    updateScriptLog "Exiting …"

    # Stop `caffeinate` process
    updateScriptLog "De-caffeinate …"
    killProcess "caffeinate"

    # Remove welcomeCommandFile
    if [[ -e ${welcomeCommandFile} ]]; then
        updateScriptLog "Removing ${welcomeCommandFile} …"
        rm "${welcomeCommandFile}"
    fi

    # Remove setupYourMacCommandFile
    if [[ -e ${setupYourMacCommandFile} ]]; then
        updateScriptLog "Removing ${setupYourMacCommandFile} …"
        rm "${setupYourMacCommandFile}"
    fi

    # Remove failureCommandFile
    if [[ -e ${failureCommandFile} ]]; then
        updateScriptLog "Removing ${failureCommandFile} …"
        rm "${failureCommandFile}"
    fi
 #   rm -rf /Library/Application\ Support/Dialog/
 #   rm -rf /usr/local/bin/dialog
    updateScriptLog "Goodbye!"
    exit "${1}"


}



####################################################################################################
#
# Pre-flight Checks
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    echo "This script must be run as root; exiting."
    exit 1
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
    updateScriptLog "*** Created log file via script ***"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ${debugMode} == "true" ]]; then
    updateScriptLog "\n\n###\n# DEBUG MODE | Setup Your Mac (${scriptVersion})\n###\n"
else
    updateScriptLog "\n\n###\n# Setup Your Mac (${scriptVersion})\n###\n"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm Setup Assistant complete and user at Desktop
# Useful for triggering on Enrollment Complete and will not pause if run via Self Service
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dockStatus=$( pgrep -x Dock )
updateScriptLog "Waiting for Desktop …"

while [[ "$dockStatus" == "" ]]; do
    updateScriptLog "Desktop is not loaded; waiting 5 seconds …"
    sleep 5
    dockStatus=$( pgrep -x Dock )
done



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate swiftDialog is installed
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogCheck



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Ensure computer does not go to sleep while running this script (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "Caffeinating this script (pid=$$)"
caffeinate -dimsu -w $$ &


####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display Welcome Screen and capture user's interaction
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ${assetTagCapture} == "true" ]]; then

    assetTag=$( eval "$dialogWelcomeCMD" | awk -F " : " '{print $NF}' )
    dialogProcessID=$!

    if [[ -z ${assetTag} ]]; then
        returncode="2"
    else
        returncode="0"
    fi

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Evaluate User Interaction at Welcome Screen
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ${assetTagCapture} == "true" ]]; then

    case ${returncode} in

        0)  ## Process exit code 0 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} entered an Asset Tag of ${assetTag} and clicked Continue"
            eval "${dialogSetupYourMacCMD[*]}" & sleep 0.3
            dialogProcessID=$!
            dialogUpdateSetupYourMac "message: Asset Tag reported as \`${assetTag}\`. $message"
            if [[ ${debugMode} == "true" ]]; then
                dialogUpdateSetupYourMac "title: DEBUG MODE | $title"
            fi
            ;;

        2)  ## Process exit code 2 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} clicked Quit when prompted to enter Asset Tag"
            quitScript "0"
            ;;

        3)  ## Process exit code 3 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} clicked infobutton"
            /usr/bin/osascript -e "set Volume 3"
            /usr/bin/afplay /System/Library/Sounds/Tink.aiff
            ;;

        4)  ## Process exit code 4 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} allowed timer to expire"
            eval "${dialogSetupYourMacCMD[*]}" & sleep 0.3
            dialogProcessID=$!
            ;;

        *)  ## Catch all processing
            updateScriptLog "WELCOME DIALOG: Something else happened; Exit code: ${returncode}"
            quitScript "1"
            ;;

    esac

else

    eval "${dialogSetupYourMacCMD[*]}" & sleep 0.3
    dialogProcessID=$!
    if [[ ${debugMode} == "true" ]]; then
        dialogUpdateSetupYourMac "title: DEBUG MODE | $title"
    fi

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Iterate through policy_array JSON to construct the list for swiftDialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialog_step_length=$(get_json_value "${policy_array[*]}" "steps.length")
for (( i=0; i<dialog_step_length; i++ )); do
    listitem=$(get_json_value "${policy_array[*]}" "steps[$i].listitem")
    list_item_array+=("$listitem")
    icon=$(get_json_value "${policy_array[*]}" "steps[$i].icon")
    icon_url_array+=("$icon")
done



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set progress_total to the number of steps in policy_array
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

progress_total=$(get_json_value "${policy_array[*]}" "steps.length")
updateScriptLog "SETUP YOUR MAC DIALOG: progress_total=$progress_total"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# The ${array_name[*]/%/,} expansion will combine all items within the array adding a "," character at the end
# To add a character to the start, use "/#/" instead of the "/%/"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

list_item_string=${list_item_array[*]/%/,}
dialogUpdateSetupYourMac "list: ${list_item_string%?}"
for (( i=0; i<dialog_step_length; i++ )); do
    dialogUpdateSetupYourMac "listitem: index: $i, icon: ${setupYourMacPolicyArrayIconPrefixUrl}${icon_url_array[$i]}, status: pending, statustext: Pending …"
done
dialogUpdateSetupYourMac "list: show"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set initial progress bar
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

progress_index=0
dialogUpdateSetupYourMac "progress: $progress_index"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Close Welcome Screen
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogUpdateWelcome "quit:"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# This for loop will iterate over each distinct step in the policy_array array
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

for (( i=0; i<dialog_step_length; i++ )); do

    # Increment the progress bar
    dialogUpdateSetupYourMac "progress: $(( i * ( 100 / progress_total ) ))"

    # Creating initial variables
    listitem=$(get_json_value "${policy_array[*]}" "steps[$i].listitem")
    icon=$(get_json_value "${policy_array[*]}" "steps[$i].icon")
    progresstext=$(get_json_value "${policy_array[*]}" "steps[$i].progresstext")

    trigger_list_length=$(get_json_value "${policy_array[*]}" "steps[$i].trigger_list.length")

    # If there's a value in the variable, update running swiftDialog

    if [[ -n "$listitem" ]]; then dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Installing …, "; fi
    if [[ -n "$icon" ]]; then dialogUpdateSetupYourMac "icon: ${setupYourMacPolicyArrayIconPrefixUrl}${icon}"; fi
    if [[ -n "$progresstext" ]]; then dialogUpdateSetupYourMac "progresstext: $progresstext"; fi
    if [[ -n "$trigger_list_length" ]]; then
        for (( j=0; j<trigger_list_length; j++ )); do
            # Setting variables within the trigger_list
            trigger=$(get_json_value "${policy_array[*]}" "steps[$i].trigger_list[$j].trigger")
            path=$(get_json_value "${policy_array[*]}" "steps[$i].trigger_list[$j].path")

            # If the path variable has a value, check if that path exists on disk
            if [[ -d "$path" ]]; then
                run_jamf_trigger "$trigger"

            else
                 updateScriptLog "SETUP YOUR MAC DIALOG: INFO: $path exists, moving on"
                if [[ "$debugMode" = true ]]; then sleep 0.5; fi

            fi
        done
    fi

    # Validate the expected path exists
    updateScriptLog "SETUP YOUR MAC DIALOG: Testing for \"$path\" …"
    if [[ -f "$path" ]] || [[ -z "$path" ]]; then
        dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: App-live"
        jamfProPolicyTriggerFailure="failed"
        jamfProPolicyPolicyNameFailures+="• $listitem  \n"
    else
        dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Deleted"

        if [[ "$trigger" == "recon" ]]; then
            dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Updated"
        fi
    fi

done



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Complete processing and enable the "Done" button
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

finalise