#!/bin/bash
# PI-101392 software update issue 
# This script tested on Monterey, ventura sevices & it may not work some time try again. 
# Created By : Manikandan @mani2care
# On : 16-Feb-2023

function Date_time(){
	#Know the current time zone 
	/usr/sbin/systemsetup -gettimezone

	#You can use the below script to turn on location services (requires restart) and then Set time zone automatically using current location will enable.

	## enabling location services
	enabled=$(sudo -u "_locationd" defaults -currentHost read "/var/db/locationd/Library/Preferences/ByHost/com.apple.locationd" LocationServicesEnabled > /dev/null)
	if [ ! $enabled = "1" ]; then
	    sudo -u "_locationd" defaults -currentHost write "/var/db/locationd/Library/Preferences/ByHost/com.apple.locationd" LocationServicesEnabled -int 1 > /dev/null
	    uuid=$(/usr/sbin/system_profiler SPHardwareDataType | grep "Hardware UUID" | cut -c22-57)
		/usr/bin/defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd.$uuid LocationServicesEnabled -int 1 > /dev/null
	    echo "location service enabled."
	else
	    echo "location service already enabled."
	fi

	#list of Public_Time_Servers.md [https://gist.github.com/mutin-sa/eea1c396b1e610a2da1e5550d94b0453]
	## # set time zone automatically using current location 
	/usr/bin/defaults write /Library/Preferences/com.apple.timezone.auto Active -bool YES > /dev/null
	/usr/bin/defaults write /private/var/db/timed/Library/Preferences/com.apple.timed.plist TMAutomaticTimeOnlyEnabled -bool YES > /dev/null
	/usr/bin/defaults write /private/var/db/timed/Library/Preferences/com.apple.timed.plist TMAutomaticTimeZoneEnabled -bool YES > /dev/null
	#set date and time automatically
	/usr/sbin/systemsetup -setusingnetworktime on
	#Know the current time zone 
	/usr/sbin/systemsetup -gettimezone
	#Know the current time zone server
	/usr/sbin/systemsetup -getnetworktimeserver
	sudo kill -HUP "$(pgrep locationd)"
	sudo /usr/bin/killall SystemUIServer
	ps -ef | grep 'timed' | grep -v grep | awk '{print $2}' | xargs -r kill -9
	echo
}

#Dade and time call function  
Date_time

#Kill the system preferance (Monterey and below ) | system settings (Ventura and above)
ps -ef | grep '/System/Applications/System Preferences.app/Contents/MacOS/System Preferences' | grep -v grep | awk '{print $2}' | xargs -r kill -9
ps -ef | grep '/System/Applications/System Settings.app/Contents/MacOS/System Settings' | grep -v grep | awk '{print $2}' | xargs -r kill -9

sudo rm /Library/Preferences/com.apple.SoftwareUpdate.plist > /dev/null
#sudo rm ~/Library/Preferences/com.apple.SoftwareUpdate.plist > /dev/null
echo "Deleting the SoftwareUpdate.Plist"

sudo rm -rf "/macOS Install Data"
echo "Deleting the Existing Downloaded Updates"
echo

pid1=$(pgrep SoftwareUpdateNotificationManager)
pid2=$(pgrep com.apple.preferences.softwareupdate.remoteservice)
pid3=$(pgrep com.apple.MobileSoftwareUpdate.CleanupPreparePathService)
pid4=$(pgrep com.apple.MobileSoftwareUpdate.UpdateBrainService)

	if [ "$pid1" = "" ]; then
		echo "Software Update NotificationManager not available"
	else
		kill -9 "$pid1"
		ps -ef | grep 'SoftwareUpdateNotificationManager' | grep -v grep | awk '{print $2}' | xargs -r kill -9
		echo "Software Update NotificationManager process $pid1 killed"
	fi

		if [ "$pid2" = "" ]; then
			echo "Software update Remoteservice not available"
		else
			kill -9 "$pid2"
			ps -ef | grep 'com.apple.preferences.softwareupdate.remoteservice' | grep -v grep | awk '{print $2}' | xargs -r kill -9
			echo "Software update Remoteservice process $pid2 killed"
		fi

			if [ "$pid3" = "" ]; then
				echo "Software update CleanupPreparePathService not available"
			else
				kill -9 "$pid3"
				ps -ef | grep 'com.apple.MobileSoftwareUpdate.CleanupPreparePathService' | grep -v grep | awk '{print $2}' | xargs -r kill -9
				echo "Software update CleanupPreparePathService process $pid3 killed"
			fi

				if [ "$pid4" = "" ]; then
					echo "Software Update BrainService not available"
				else
					kill -9 "$pid4"
					ps -ef | grep 'com.apple.MobileSoftwareUpdate.UpdateBrainService' | grep -v grep | awk '{print $2}' | xargs -r kill -9
					echo "Software Update BrainService process $pid4 killed"
				fi

echo
sleep 2
#kickstart softwareupdate && register an IPC service by API bootstrapcheckin
sudo launchctl kickstart -k system/com.apple.softwareupdated > /dev/null
sudo launchctl kickstart -kp system/com.apple.suhelperd > /dev/null
echo "Software update kickstarted"
sleep 2

	function system_verification(){
		echo "Verifying Volume"
		diskutil verifyVolume / > /dev/null
	}

system_verification

#force the update via MDM
#sudo /usr/libexec/mdmclient AvailableOSUpdates > /dev/null
#check the update count
sudo softwareupdate -l > /dev/null
sleep 2

LastUpdatesAvailable=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist LastUpdatesAvailable)

if [ "$LastUpdatesAvailable" = "" ]; then
	echo "Unable to find the Updates try after 1 min "
else
	echo "Number of updates available :$LastUpdatesAvailable"
	sudo /usr/bin/open "/System/Library/CoreServices/Software Update.app"
fi

exit 0