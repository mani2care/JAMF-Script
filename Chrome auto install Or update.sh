#!/bin/sh
#####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#	ChromeInstall.sh -- Installs or updates Google Chrome
#
# SYNOPSIS
#	sudo ChromeInstall.sh
#   Script to download and install Chrome.
#   Must be ran when logged in as the end user.
#   Note: Chrome now requires 10.9 or later.  This script does NOT check for a valid OS version.
#
####################################################################################################
#
# HISTORY
#
#	Version: 2.0
#
#  - Anil Peerlapalli, 07.02.2022
#
#   Based heavily on FirefoxInstall.sh by Joe Farage, 18.03.2015 and Matt Bezzo, 22.06.2016
#
####################################################################################################

########################################
############## Variables ###############
########################################

dmgfile="GC.dmg"

# URL to get current version of Chrome
downloadURL1="https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg"
downloadURL2="https://dl.google.com/chrome/mac/universal/stable/CHFA/googlechrome.dmg"

# Get the currently logged in user
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

########################################
############## Functions ###############
########################################

log(){
NOW="$(date +"%Y-%m-%d %H:%M:%S")"
echo "$NOW": "$1"
}

########################################
########## Begin Main Program ##########
########################################

# Logging for troubleshooting - view the log at /var/log/f5chromeinstall.log
touch /var/log/chromeinstall.log
exec 2>&1>/var/log/chromeinstall.log

# Are we running on Intel?
if [ '`/usr/bin/uname -p`'="i386" -o '`/usr/bin/uname -p`'="x86_64" ]; then
	# Download the latest version of Chrome
	/usr/bin/curl -s -o /tmp/$dmgfile $downloadURL1
else
  /usr/bin/curl -s -o /tmp/$dmgfile $downloadURL2
fi

log "Downloading latest available version"

# Mount .dmg
log "Mounting .dmg"
hdiutil attach -noverify -nobrowse -quiet /tmp/$dmgfile

# Get latest version from the downloaded app
log "Getting latest version"
latestver=`/usr/bin/defaults read /Volumes/Google\ Chrome/Google\ Chrome.app/Contents/Info CFBundleShortVersionString`
log "Latest Version is: $latestver"

# Unmount .dmg
log "Unmounting .dmg"
hdiutil unmount -quiet /Volumes/Google\ Chrome

# Get the version number of the currently-installed Chrome, if any.
log "Checking the version of the currently installed app"
if [ -e "/Applications/Google Chrome.app" ]; then
	currentinstalledver=`/usr/bin/defaults read /Applications/Google\ Chrome.app/Contents/Info CFBundleShortVersionString`
	log "Currently installed version is: $currentinstalledver"
	if [ ${latestver} = ${currentinstalledver} ]; then
		log "Chrome is current. Exiting"
		exit 0
	fi
else
	currentinstalledver="none"
	log "Chrome is not installed"
fi

# Compare the two versions, if they are different or Chrome is not present then install the new version.
if [ "${currentinstalledver}" != "${latestver}" ]; then
  log "Current Chrome version: ${currentinstalledver}"
	log "Available Chrome version: ${latestver}"
	log "Mounting .dmg of newer version."
	hdiutil attach -noverify -nobrowse -quiet /tmp/$dmgfile
	log "Removing current version..." # Need to do this because if the app was installed by anyone other than the currently logged in user, the next command will fail
	rm -rf /Applications/Google\ Chrome.app
	log "Installing as currently logged in user..." #This maintains the correct permissions and should allow for successful updates by the user
	su $loggedInUser -c 'ditto "/Volumes/Google Chrome/Google Chrome.app" "/Applications/Google Chrome.app"'
	sleep 2
	log "Unmounting installer disk image."
	hdiutil unmount -quiet /Volumes/Google\ Chrome
	sleep 2
	log "Deleting disk image."
	rm /tmp/${dmgfile}

	#double check to see if the new version got updated
	newlyinstalledver=`/usr/bin/defaults read /Applications/Google\ Chrome.app/Contents/Info CFBundleShortVersionString`
      if [ "${latestver}" = "${newlyinstalledver}" ]; then
          log "SUCCESS: Chrome has been updated to version ${newlyinstalledver}"
   # /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -title "Chrome Installed" -description "Chrome has been updated." &
      else
          log "ERROR: Chrome update unsuccessful, version remains at ${currentinstalledver}."
		exit 1
	fi

# If Chrome is up to date already, just log it and exit.
else
	log "Chrome is already current with version ${currentinstalledver}."
fi

exit 0
