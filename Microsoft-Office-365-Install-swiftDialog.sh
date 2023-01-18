#!/bin/bash

# Eddited by manikandan(@mani2care)
# Download Latest Office 365 BusinessPro Suite Installer
# 23-Dec-2022
# https://macadmins.software/
# https://github.com/acodega/dialog-scripts/blob/main/officeInstallProgress.sh

#Note : Via jamf In policy mention the parameter values any one value in below.
# Word
# Excel
# Powerpoint
# Onedrive
# Onenote
# Outlook
# MAU
# MSTeamsAudiodriver
# MSTeams
# FullOfficesuite365businesspro
# FullOfficesuite365

expectedTeamID="UBF8T346G9" # '/usr/sbin/spctl -a -vv -t install package.pkg' to get the expected Team ID
dialogApp="/usr/local/bin/dialog"
workDirectory=$( /usr/bin/basename "$0" )
tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX")
/bin/chmod 777 "$tempDirectory"
dialog_command_file="/var/tmp/dialog.log"

echo "Fetching the Latest XML details"

MACADMINS_URL="https://macadmins.software/latest.xml"
xmlLocation=$(curl -H "Accept: text/xml" -sfk ${MACADMINS_URL})

LATEST_VERSION=$(echo "${xmlLocation}" | xmllint --xpath "//latest/vl2019/text()" -)
echo "Office Suite Installer version : ${LATEST_VERSION}"

function install_software () {
    SOFTWARE_ID=$1
    SOFTWARE_NAME=$2
          echo
          echo "Injected Microsoft office is ${1} ${2} "

            if [[ "$2" == "MSTeamsAudiodriver" ]]; then
                url=$(echo "${xmlLocation}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/moreurl/text()' -)
                SHA256=""
            else
                url=$(echo "${xmlLocation}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/download/text()' -)
                SHA256=$(echo "${xmlLocation}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/sha256/text()' -)
            fi
    icon=$(echo "${xmlLocation}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/icon/text()' -)
    VERSION=$(echo "${xmlLocation}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/cfbundleshortversionstring/text()' -)
    officetitle=$(echo "${xmlLocation}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/title/text()' -)
    officeappname=$(echo "${xmlLocation}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/subtext/text()' -)
    publishedon=$(echo "${xmlLocation}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/lastupdated/text()' -)
    minos=$(echo "${xmlLocation}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/min_os/text()' -)
    macho=$(echo "${xmlLocation}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/mach-o/text()' -)
    linkID=$( echo 'cat //package[2]/download/text()' | xmllint --shell /private/var/tmp/office-version-output.xml |grep -Ev '^/ >|^ -+$' | sed -E 's/.*(id=|folders\/)([^&?/]*).*/\2/' )

    echo
    echo "Title             : ${officetitle}"
    echo "URL               : ${url}"
    echo "Version           : ${VERSION}"
    echo "App-subtext       : ${officeappname}"
    echo "SHA256            : ${SHA256}"
    echo "Publishedon       : ${publishedon}"
    echo "OSsupportfrom     : ${minos}"
    echo "Hardwaresupport   : ${macho}"
    echo "Url link ID       : ${linkID}"
    echo
}

for param in "$@"; do
    case $param in 
        "Word")
            install_software "com.microsoft.word.standalone.365" "Word"
            ;;
        "Excel")
            install_software "com.microsoft.excel.standalone.365" "Excel"
            ;;
        "Powerpoint")
            install_software "com.microsoft.powerpoint.standalone.365" "Powerpoint"
            ;;
        "Onedrive")
            install_software "com.microsoft.onedrive.standalone" "OneDrive"
            ;;
        "Onenote")
            install_software "com.microsoft.onenote.standalone.365" "OneNote"
            ;;
        "Outlook")
            install_software "com.microsoft.outlook.standalone.365" "Outlook"
            ;;
        "MAU")
            install_software "com.microsoft.autoupdate.standalone" "MAU"
            ;;
        "MSTeamsAudiodriver")
            install_software "com.microsoft.teams.standalone" "MSTeamsAudiodriver"
            ;;
        "MSTeams")
            install_software "com.microsoft.teams.standalone" "MSTeams"
            ;;
        "FullOfficesuite365businesspro")
            install_software "com.microsoft.office.suite.365.businesspro" "FullOfficesuite365businesspro"
            ;;
        "FullOfficesuite365")
            install_software "com.microsoft.office.suite.365" "FullOfficesuite365"
            ;;
        *)
            echo "Unknown Parameter"
            exit 0
    esac
    shift
done
echo "Unknown Parameter hence unable to process further"
exit 1

# serializerURL="https://qwerty.domain.net/OfficeForMac/Microsoft_Office_LTSC_2021_VL_Serializer.pkg" # Replace with the URL to your serializer PKG, Comment line 6-8 if you're not serializing
# UNAME=abc # Replace with the username, if needed, to curl your PKG. Comment line 6-8 if you're not serializing
# PWORD=xyz # Replace with the password, if needed, to curl your PKG. Comment line 6-8 if you're not serializing

function dialog_command(){
  echo $1
  echo $1 >> $dialog_command_file
}
echo "$dialog_command_file"

function Removing_tempDirectory(){
    # Remove welcomeCommandFile
    if [[ -e ${tempDirectory} ]]; then
        dialog_command "Removing ${tempDirectory} …"
        rm -rf "${tempDirectory}"
    fi
} 
function finalize(){
  dialog_command "overlayicon: SF=checkmark.circle.fill,weight=bold,colour1=#00ff44,colour2=#075c1e"
  dialog_command "progresstext: ${officetitle} installition is complete"
  dialog_command "progress: complete"
  dialog_command "button1text: Done"
  dialog_command "button1: enable" 
  Removing_tempDirectory
  exit 0
}

function finalizeError(){
  dialog_command "overlayicon: SF=xmark.circle.fill,weight=bold,colour1=#BB1717,colour2=#F31F1F"
  dialog_command "progress: 0"
  dialog_command "button1text: Close"
  dialog_command "button1: enable" 
  exit 0
}

function dialogAppleScript(){
  message="A problem was encountered setting up this Mac. Please contact IT."
  currentUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')
  if [[ "$currentUser" != "" ]]; then
    currentUserID=$(id -u "$currentUser")
    launchctl asuser "$currentUserID" /usr/bin/osascript <<EOD
      button returned of ¬
      (display dialog "$message" ¬
      buttons {"OK"} ¬
      default button "OK")
EOD
  fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Kill a specified process (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function killProcess() {

    process="$1"
    if process_pid=$( pgrep -a "${process}" 2>/dev/null ) ; then
        dialog_command "Attempting to terminate the '$process' process …"
        dialog_command "(Termination message indicates success.)"
        kill "$process_pid" 2> /dev/null
        if pgrep -a "$process" >/dev/null ; then
            dialog_command "ERROR: '$process' could not be terminated."
        fi
    fi
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Quit Script (thanks, @bartreadon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function quitScript() {

    dialog_command "Exiting …"

    # Stop `caffeinate` process
    dialog_command "De-caffeinate …"
    killProcess "caffeinate"
    Removing_tempDirectory
    dialog_command "Goodbye!"
    exit "${1}"

}

##Validating the old Dialog.app if its old version it will install always latest one.

function dialogCheck(){
  local dialogApp="/Library/Application Support/Dialog/Dialog.app"
  local installedappversion=$(defaults read "/Library/Application Support/Dialog/Dialog.app/Contents/Info.plist" CFBundleShortVersionString || echo 0)
  local requiredVersion=0
  if [ ! -z $1 ]; then
    requiredVersion=$1
  fi

  # Check for Dialog and install if not found
  #is-at-least $requiredVersion $installedappversion
  local result=$?
  if [ ! -e "${dialogApp}" ] || [ $result -ne 0 ]; then
    dialogInstall
  else
    echo "Dialog found & up to date"
  fi
}

function dialogInstall(){
  # Get the URL of the latest PKG From the Dialog GitHub repo
  local dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
  # Expected Team ID of the downloaded PKG
  local expectedDialogTeamID="PWA5E9TQ59"
  
    # Create temporary working directory
    local workDirectory=$( /usr/bin/basename "$0" )
    local tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
    # Download the installer package
    /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"
    # Verify the download
    local teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
    # Install the package if Team ID validates
    if [ "$expectedDialogTeamID" = "$teamID" ] || [ "$expectedDialogTeamID" = "" ]; then
      /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
    else
      # displayAppleScript # uncomment this if you're using my displayAppleScript function
      echo "Dialog Team ID verification failed."
      #dialogAppleScript
        # Remove the temporary working directory when done
Removing_tempDirectory
      exit 1 # uncomment this if want script to bail if Dialog install fails
    fi
}

function serializeOffice(){
  # download the serializer package and capture the % percentage sign progress for Dialog display
  # We all know not to use cURL with a username and password in the script. Yada yada. Remove --user $UNAME:$PWORD if not required.
  /usr/bin/curl --user $UNAME:$PWORD -L "$serializerURL" -# -o "$tempDirectory/Microsoft_Office_LTSC_2021_VL_Serializer.pkg" 2>&1 | while IFS= read -r -n1 char; do
    [[ $char =~ [0-9] ]] && keep=1 ;
    [[ $char == % ]] && dialog_command "progresstext: Downloading ${officetitle} License ${progress}%" && progress="" && keep=0 ;
    [[ $keep == 1 ]] && progress="$progress$char" ;
  done

  # verify the serializer download
  teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Microsoft_Office_LTSC_2021_VL_Serializer.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
  echo "Team ID for downloaded package: $teamID"

  # install the serializer package if Team ID validates
  if [ "$expectedTeamID" = "$teamID" ] || [ "$expectedTeamID" = "" ]; then
    dialog_command "progresstext: Installing ${officetitle} License..."
    dialog_command "progress: 1"
    /usr/sbin/installer -pkg "$tempDirectory/Microsoft_Office_LTSC_2021_VL_Serializer.pkg" -target /
  else
    dialog_command "progresstext: Something went wrong. Please try again or contact IT. (Invalid License URL or License Team ID)"
    finalizeError
    exitCode=1
    quitScript
    exit $exitCode
  fi
}

# Begin

setupAssistantProcess=$(pgrep -l "Setup Assistant")
until [ "$setupAssistantProcess" = "" ]; do
  echo "$(date "+%a %h %d %H:%M:%S"): Setup Assistant Still Running. PID $setupAssistantProcess."
  sleep 1
  setupAssistantProcess=$(pgrep -l "Setup Assistant")
done
echo "$(date "+%a %h %d %H:%M:%S"): Out of Setup Assistant" 2>&1
echo "$(date "+%a %h %d %H:%M:%S"): Logged in user is $(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')"

finderProcess=$(pgrep -l "Finder")
until [ "$finderProcess" != "" ]; do
  echo "$(date "+%a %h %d %H:%M:%S"): Finder process not found. Assuming device is at login screen. PID $finderProcess"
  sleep 1
  finderProcess=$(pgrep -l "Finder")
done

echo "$(date "+%a %h %d %H:%M:%S"): Finder is running"
echo "$(date "+%a %h %d %H:%M:%S"): Logged in user is $(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')"

dialogCheck

# this will check for a version that does not (yet) exist. until this version is released it will always run the download and install.
echo "Checking with version 2.0.1"
dialogCheck 2.0.1

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Ensure computer does not go to sleep while running this script (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialog_command "Caffeinating this script (pid=$$)"
caffeinate -dimsu -w $$ &

# initial dialog starting arguments
message="Installing ${officetitle} \n\n $officeappname : (${VERSION})"

overlayicon=$icon
# set icon based on whether computer is a desktop or laptop
hwType=$(/usr/sbin/system_profiler SPHardwareDataType | grep "Model Identifier" | grep "Book")  
if [ "$hwType" != "" ]; then
  icon="SF=laptopcomputer.and.arrow.down"
  else
  icon="SF=desktopcomputer.and.arrow.down"
fi

dialogCMD="$dialogApp --title none \
--message \"$message\" \
--alignment center \
--icon \"$overlayicon\" \
--overlayicon \"$icon\" \
--centericon \
--commandfile \"$dialog_command_file\" \
--ontop \
--moveable \
--small \
--progress 2 \
--button1text \"Please Wait\" \
--button1disabled"

echo $dialogCMD
# Launch dialog and run it in the background sleep for a second to let thing initialise
eval $dialogCMD &
sleep 2

# now start executing

dialog_command "progresstext: Starting..."

if [ -z "$serializerURL" ]; then
  echo "Microsoft Serializer not specified. Continuing on."
else
  serializeOffice
fi

function Officedownload(){
# download the installer package and capture the % percentage sign progress for Dialog display
dialog_command "progress: 0"
/usr/bin/curl --retry 10 --retry-delay 5 -L "${url}" -# -o "$tempDirectory/$officetitle.pkg" 2>&1 | while IFS= read -r -n1 char; do
  [[ $char =~ [0-9] ]] && keep=1 ;
  [[ $char == % ]] && dialog_command "progresstext: Downloading version(${VERSION}) : ${progress}%" && progress="" && keep=0 ;
  [[ $keep == 1 ]] && progress="$progress$char" ;
done
}
Officedownload

# verify the download
#teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/${officetitle}.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
#echo "Team ID for downloaded package: $teamID"

echo "Verifying Checksum for the package ${officetitle}"
CHECKSUM=$(shasum -a 256 "$tempDirectory/${officetitle}.pkg" | awk -F" " '{print $1}')

# install the package if Team ID validates
if [ "$SHA256" = "$CHECKSUM" ] || [ "$SHA256" = "" ]; then
#if [ "$expectedTeamID" = "$teamID" ] && [ "$teamID" != "" ] && ["$progress" != *"56"* ]; then
  dialog_command "progresstext: Installing ${officetitle} : ${VERSION}"
  dialog_command "progress: 1"
  /usr/sbin/installer -pkg "$tempDirectory/${officetitle}.pkg" -target /
                       if [[ $? == 0 ]]; then
                        dialog_command "${officetitle} Successfully installed"
                          finalize
                    else
                        dialog_command "[ERROR] Unable to install ${officetitle}"
                        finalizeError
                        exitCode=1
                    fi

else
  dialog_command "progresstext: Something went wrong. Please try again "
  finalizeError
  exitCode=1
fi

# remove the temporary working directory when done
Removing_tempDirectory
exit $exitCode
