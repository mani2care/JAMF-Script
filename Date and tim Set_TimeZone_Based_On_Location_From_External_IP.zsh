#!/bin/zsh
##############################################
##############################################
# Script to find the systems current time zone based on their approximate physical location pulled from the system's current external IP address.
# Once the time zone is identified, the system is updated to be set to the result.
# After setting the time zone, the script verifies that "Set Date and Time Automatically" is enabled to avoid any issues
#
# Find the system's current external IP Address
myIP=$(curl -L -s --max-time 10 http://checkip.dyndns.org | egrep -o -m 1 '([[:digit:]]{1,3}.){3}[[:digit:]]{1,3}')
#
# Bump the IP address against ip-api.com to pull the current time zone for it's approximate location
timeZone=$(curl -L -s --max-time 10 "http://ip-api.com/line/$myIP?fields=timezone")
#
# Set the time zone based on the result
sudo systemsetup -settimezone "$timeZone"
#
# Ensure that "Set Date and Time Automatically" is checked
sudo systemsetup -setusingnetworktime on
exit 0
