#!/bin/bash
# PI-101392 software update issue 
# This script tested on Monterey, ventura sevices & it may not work some time try again. 
# Created By : Manikandan @mani2care
# On : 16-Feb-2023
# version 2.0

# Validated following 
########################################################################################
# 1) Script will be supported from 11.0 to 13.X
# 2) Checking the site test google.com & apple.com
# 3) Enable the enable_location_services_and_set_time_zone.
# 4) kill_system_preferences_or_system_settings
# 5) cleanup_software_update_files_and_processes
# 4) restart_softwareupdate_kickstart
# 7) Install_available_update  
########################################################################################
# set -x

# Determine macOS version.
OS_VERSION=$(/usr/bin/sw_vers -productVersion)
OS_MAJOR=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F . '{print $1}')
OS_MINOR=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F . '{print $2}')
OS_PATCH=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F . '{print $3}')

#Check the version & limit the script to running
if [[ "$OS_MAJOR" -le 10 ]]; then
	echo "This script is not supported for this version $OS_MAJOR upgrade the macOS to 11 and above"
	exit 0
fi

# We need to be connected to the internet in order to download updates.
function Software_update_catalo_test() {

			# Array of servers to test
			SERVERS=(
			  gg.apple.com
			  gs.apple.com
			  ig.apple.com
			  mesu.apple.com
			  oscdn.apple.com
			  skl.apple.com
			  swcdn.apple.com
			  swdist.apple.com
			  swscan.apple.com
			  xp.apple.com
			  swdownload.apple.com
			  configuration.apple.com
			  updates-http.cdn-apple.com
			  updates.cdn-apple.com
			)

			# Function to check internet connection
			check_internet(){
			  ping -c 1 google.com > /dev/null 2>&1
			  if [ $? -ne 0 ]; then
			    return 1
			  fi
			  return 0
			}

			# Function to check network restrictions
			check_network_restrictions(){
			  ping -c 1 apple.com > /dev/null 2>&1
			  if [ $? -ne 0 ]; then
			    return 1
			  fi
			  return 0
			}

			# Retry ping tests up to 3 times
			for i in {1..3}; do
			  # Check internet connection
			  check_internet
			  if [ $? -ne 0 ]; then
			    echo "Error: Internet connection is not available (Attempt $i of 3)"
			    sleep 5
			  fi

			  # Check network restrictions
			  check_network_restrictions
			  if [ $? -ne 0 ]; then
			    echo "Error: Network restrictions are blocking the connection (Attempt $i of 3)"
			    sleep 5
			    continue
			  fi
			  # If both checks pass, break out of loop and continue script
			  break
			done

	if [ $i == 3 ]; then
	  	echo
	    echo "Error: Network restrictions are blocking the connection"
	    traceroute apple.com
	    exit 0
	  fi

			# Check active network interfaces
			if ifconfig en0 | grep -q "inet "; then
			  # Wi-Fi interface is active
			  WIFI_IP=$(ifconfig en0 | grep "inet " | awk '{print $2}')
			fi

			# Display IP addresses of active interfaces
			if [ -n "$WIFI_IP" ]; then
			  echo "Wi-Fi IP : $WIFI_IP"
			fi

			if ifconfig | grep -q "utun"; then
			  # VPN interface is active
			  for i in {0..9}; do
			    if ifconfig utun$i > /dev/null 2>&1 && ifconfig utun$i | grep -q "inet "; then
			      IP=$(ifconfig utun$i | grep "inet " | awk '{print $2}')
			      #echo "VPN IP address (utun$i): $IP"
			      echo "VPN IP   : $IP"
			    fi
			  done
			fi

			if ifconfig en1 | grep -q "inet "; then
			  # Thunderbolt bridge interface is active
			  IP=$(ifconfig en1 | grep "inet " | awk '{print $2}')
			  echo "Thunderbolt IP address: $IP"
			elif ifconfig en2 | grep -q "inet "; then
			  # Ethernet interface is active
			  IP=$(ifconfig en2 | grep "inet " | awk '{print $2}')
			  echo "Ethernet IP address: $IP"
			elif ifconfig awdl0 | grep -q "inet "; then
			  # Apple Wireless Direct Link interface is active
			  IP=$(ifconfig awdl0 | grep "inet " | awk '{print $2}')
			  echo "AWDL IP address: $IP"
			elif ifconfig bridge0 | grep -q "inet "; then
			  # Bridge interface is active
			  IP=$(ifconfig bridge0 | grep "inet " | awk '{print $2}')
			  echo "Bridge IP address: $IP"
			elif ifconfig en3 | grep -q "inet "; then
			  # Thunderbolt 2 interface is active
			  IP=$(ifconfig en3 | grep "inet " | awk '{print $2}')
			  echo "Thunderbolt 2 IP address: $IP"
			elif ifconfig en4 | grep -q "inet "; then
			  # Thunderbolt 3 interface is active
			  IP=$(ifconfig en4 | grep "inet " | awk '{print $2}')
			  echo "Thunderbolt 3 IP address: $IP"
			fi

			echo
			  # Test reachability of each server
			  for SERVER in "${SERVERS[@]}"; do
			    ATTEMPTS=1
			    while [ $ATTEMPTS -gt 0 ]; do
			      if ping -c 1 "$SERVER" > /dev/null 2>&1; then
			        echo "Reachable     : $SERVER"      
			        break
			      else
			        if [ $ATTEMPTS -gt 1 ]; then
			          ATTEMPTS=$((ATTEMPTS-1))
			          sleep 1
			        else
			          echo "Not-reachable : $SERVER"
			          ATTEMPTS=$((ATTEMPTS-1))
			          sleep 1
			        fi
			      fi
			    done
			  done
}
Software_update_catalo_test
echo
# Function to stop software update daemon if it is running
function stop_software_update_daemon(){
		#Check if System Integrity Protection is Enabled on Mac if yes this function will not work.
		csrstatus=$(/usr/bin/csrutil status | /usr/bin/awk '{print $NF}')
		if [ "$csrstatus" = "disabled." ]
		then
		    echo "System Integrity Protection is not Enabled"
		    if sudo launchctl list | grep -i softwareupdated > /dev/null; then
		    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.softwareupdated.plist
		    echo "Stopped software update daemon."
		    # Remove software update catalog
			echo "Removing software update catalog..."
			sudo rm -rf /Library/Updates/*
			echo
		  fi
		else
			echo "System Integrity Protection is Enabled so unable to unload the LaunchDaemons"
		fi
}
#if you are enabling this fuction then you need to enable the stop_software_update_daemon_load function 
#stop_software_update_daemon 

# Function to enable location services and set time zone automatically
function enable_location_services_and_set_time_zone(){
		#Know the current time zone 
		/usr/sbin/systemsetup -gettimezone

		## Function to enable location services and set time zone automatically (No restart requires).
		enabled=$(sudo -u "_locationd" defaults -currentHost read "/var/db/locationd/Library/Preferences/ByHost/com.apple.locationd" LocationServicesEnabled > /dev/null)
		if [ ! $enabled = "1" ]; then
		    sudo -u "_locationd" defaults -currentHost write "/var/db/locationd/Library/Preferences/ByHost/com.apple.locationd" LocationServicesEnabled -int 1 > /dev/null
		    uuid=$(/usr/sbin/system_profiler SPHardwareDataType | grep "Hardware UUID" | cut -c22-57)
			/usr/bin/defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd.$uuid LocationServicesEnabled -int 1 > /dev/null
		    echo "location service enabled."
		else
		    echo "location service already enabled."
		fi
		echo "Time zone set automatically using current location."
		# set time zone automatically using current location refere all the servers [https://gist.github.com/mutin-sa/eea1c396b1e610a2da1e5550d94b0453]
		/usr/bin/defaults write /Library/Preferences/com.apple.timezone.auto Active -bool YES > /dev/null
		/usr/bin/defaults write /private/var/db/timed/Library/Preferences/com.apple.timed.plist TMAutomaticTimeOnlyEnabled -bool YES > /dev/null
		/usr/bin/defaults write /private/var/db/timed/Library/Preferences/com.apple.timed.plist TMAutomaticTimeZoneEnabled -bool YES > /dev/null
		#set date and time automatically
		/usr/sbin/systemsetup -setusingnetworktime on
		#Know the current time zone 
		/usr/sbin/systemsetup -gettimezone
		#Know the current time zone server
		/usr/sbin/systemsetup -getnetworktimeserver
		/usr/bin/sudo kill -HUP "$(pgrep locationd)"
		/usr/bin/sudo /usr/bin/killall SystemUIServer
		ps -ef | /usr/bin/grep 'timed' | /usr/bin/grep -v grep | /usr/bin/awk '{print $2}' | xargs -r kill -9
		echo
} 
enable_location_services_and_set_time_zone

# function to kill system preferences or system settings
function kill_system_preferences_or_system_settings() {
	if [[ "$OS_MAJOR" -ge 13 ]]; then
    	if pgrep "System Settings" > /dev/null; then
        ps -ef | grep '/System/Applications/System Settings.app/Contents/MacOS/System Settings' | grep -v grep | awk '{print $2}' | xargs -r kill -9
        echo "System Settings killed."
      fi
    fi
	if [[ "$OS_MAJOR" -le 12 ]]; then
		if pgrep "System Preferences" > /dev/null; then
	        ps -ef | grep '/System/Applications/System Preferences.app/Contents/MacOS/System Preferences' | grep -v grep | awk '{print $2}' | xargs -r kill -9
			echo "System Preferences killed."
	    fi
	fi
}
kill_system_preferences_or_system_settings

# function to clean up existing software update files and processes
function cleanup_software_update_files_and_processes(){
			# Reset/Clear ignored updates (Starting with macOS Monterey (12.x), this command has been deprecated and no longer works to clear ignored updates.)
			if [[ "$OS_MAJOR" -le 11 ]]; then
			  echo "Resetting ignored updates..."
			  sudo /usr/sbin/softwareupdate --reset-ignored > /dev/null
		  	  echo "Clearing ignored updates..."
			  sudo softwareupdate --clear-ignore > /dev/null
			  sudo softwareupdate --clear-catalog > /dev/null
			fi

			# kill software update processes
			    pids=("SoftwareUpdateNotificationManager" "com.apple.preferences.softwareupdate.remoteservice" "com.apple.MobileSoftwareUpdate.CleanupPreparePathService" "com.apple.MobileSoftwareUpdate.UpdateBrainService")
			    for pid in "${pids[@]}"; do
			        if pgrep "$pid" > /dev/null; then
			            killall "$pid"
			            echo "$pid process killed."
			        else
			            echo "$pid process not running."
			        fi
			    done

			# Remove macOS Install Data
				echo
				echo "Removing macOS Install Data..."
				/bin/rm -rf "/macOS Install Data"

			# Remove software update preferences

				plistfilecheck="/Library/Preferences/com.apple.SoftwareUpdate.plist"
				if [[ -e "$plistfilecheck" ]]; then
					echo "Deleting the SoftwareUpdate plist"
		        	/bin/rm -rf "/Library/Preferences/com.apple.SoftwareUpdate.plist"
		    	fi
}
cleanup_software_update_files_and_processes

# Run First Aid on all disks and volumes
function repairDisk_repairVolume(){
	    disks=$(diskutil list | grep "/dev/disk" | awk '{print $1}')
	    for disk in $disks; do
	        echo "Repairing disk $disk"
	        diskutil unmountDisk $disk >/dev/null 2>&1
	        diskutil repairDisk $disk -y >/dev/null 2>&1
	        diskutil mountDisk $disk >/dev/null 2>&1
	    done

	    volumes=$(diskutil list | grep "Volume " | awk '{print $NF}')
	    for volume in $volumes; do
	        echo "Running First Aid on volume $volume"
	        diskutil verifyVolume $volume >/dev/null 2>&1
	        diskutil repairVolume $volume -y >/dev/null 2>&1
	    done
}
#repairDisk_repairVolume
echo

# Start software update daemon and check for updates
function stop_software_update_daemon_load(){
    /bin/launchctl load -w /System/Library/LaunchDaemons/com.apple.softwareupdated.plist > /dev/null
    echo "Stopped software update daemon."
}
#if you are enabling this fuction then you need to enable the stop_software_update_daemon function 
#stop_software_update_daemon_load

# Restart the softwareupdate daemon
function restart_softwareupdate_kickstart(){
			if [[ "$OS_MAJOR" -eq 11 && "$OS_MINOR" -eq 0 || "$OS_VERSION" > "11.0" ]] && [[ "$OS_VERSION" < "13.3" ]]; then
			echo "Restarting com.apple.softwareupdated system service..."
			/bin/launchctl kickstart -k "system/com.apple.softwareupdated" > /dev/null
			/bin/launchctl kickstart -kp system/com.apple.suhelperd > /dev/null
			echo "Software update kickstarted"
			else
			  echo "JAMF is not recommended to launchctl kickstart mcaos version from 13.3 & your version is : $OS_VERSION"
			fi

			#Force the update via MDM
			mdmctl status > /dev/null 2>&1
			if [ $? -eq 0 ]
			then
			  echo "Forcing the software update via mdmclient"
			  sudo /usr/libexec/mdmclient AvailableOSUpdates > /dev/null
			else
			  echo "MDM not found."
			fi
			echo
			sleep 1
}
restart_softwareupdate_kickstart

function Install_available_update(){
   	sudo /usr/bin/open "/System/Library/CoreServices/Software Update.app"
    echo "Checking the software updates"
    sudo softwareupdate -l > /dev/null
    # Show the number of updates available and open the Software Update app
    sleep 20
    LastUpdatesAvailable=$(sudo defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist LastUpdatesAvailable)
    echo "Number of updates available: $LastUpdatesAvailable"
 
}
Install_available_update
exit 0