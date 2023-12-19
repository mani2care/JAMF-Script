#!/bin/bash

# Set separate power management settings for desktops and laptops
# If it's a laptop, the power management settings for "Battery" are set to have the computer sleep in 15 minutes, 
# disk will spin down in 10 minutes, the display will sleep in 5 minutes and the display itself will dim to 
# half-brightness before sleeping. While plugged into the AC adapter, the power management settings for "Charger" 
# are set to have the computer never sleep, the disk doesn't spin down, the display sleeps after 30 minutes and 
# the display dims before sleeping.
# https://derflounder.wordpress.com/2022/12/26/identifying-mac-laptops-and-desktops-from-the-command-line-by-checking-for-a-built-in-battery/
# If it's not a laptop (i.e. a desktop), the power management settings are set to have the computer never sleep, 
# the disk doesn't spin down, the display sleeps after 30 minutes and the display dims before sleeping.
#

# Detects if this Mac is a laptop or not by checking for a built-in battery.
IS_LAPTOP=$(/usr/sbin/ioreg -c AppleSmartBattery -r | awk '/BatteryInstalled/ {print $3}')

if [[ "$IS_LAPTOP" = "Yes" ]]; then
	/usr/bin/pmset -b sleep 15 disksleep 10 displaysleep 5 halfdim 1
	/usr/bin/pmset -c sleep 0 disksleep 0 displaysleep 30 halfdim 1
else
	/usr/bin/pmset sleep 0 disksleep 0 displaysleep 30 halfdim 1
fi
