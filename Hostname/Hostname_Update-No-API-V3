#!/bin/sh
# Get the JSS URL from the Mac's jamf plist file
serial=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')

# Try to get the username using profiles command
username=$(profiles -P -o stdout | grep -i -A 20 "User Info" | grep "username" | awk -F'=' '{gsub(/^ *| *$/,"",$2); print $2}' | tr -d ';')

# If the username is not found, try using the defaults command
if [ -z "$username" ]; then
    username=$(defaults read "/Library/Managed Preferences/com.abb.deviceinfo.plist" username)
fi

if [ -z "$username" ]; then
    echo "Error: Username not found from profiles or defaults. Exiting."
    exit 1
else
    # Extract the first two characters of the username
    firstCharacter=${username:0:2}

    # Ensure firstCharacter is not empty
    if [ -z "$firstCharacter" ]; then
        echo "Error: firstCharacter is empty, exiting."
        exit 1
    fi

    # Laptop or Desktop check
    TYPE=$(system_profiler SPHardwareDataType | grep -i "MacBook" | wc -l)
    [[ $TYPE -gt 0 ]] && T="L" || T="D"

    # Construct the new computer name
    newcomputerName="${firstCharacter}-${T}-${serial}"

    # Ensure the new computer name is valid
    if [[ "$newcomputerName" =~ ^[-] ]]; then
        echo "Error: Invalid computer name format '$newcomputerName', exiting."
        exit 1
    fi

    # Retrieve current computer names
    oldcomputername=$(scutil --get ComputerName)
    oldHostName=$(scutil --get HostName)
    oldLocalHostName=$(scutil --get LocalHostName)
    
    echo "Attempting to change Hostname"

    validation_check() {
        if [[ "$newcomputerName" != "$oldcomputername" || "$newcomputerName" != "$oldHostName" || "$newcomputerName" != "$oldLocalHostName" ]]; then
            echo "Old computer name: $oldcomputername"
            newcomputerName=$(echo "$newcomputerName" | tr '[:lower:]' '[:upper:]')
            echo "Assigning New computer name: $newcomputerName"

            /usr/sbin/scutil --set HostName "$newcomputerName"
            /usr/sbin/scutil --set LocalHostName "$newcomputerName"
            /usr/sbin/scutil --set ComputerName "$newcomputerName"

            # Flush DNS cache
            dscacheutil -flushcache
            killall -HUP mDNSResponder

# Read the current NetBIOS name
            currentNetBIOSName=$(defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server.plist NetBIOSName 2>/dev/null)

            # Update the NetBIOS name if it is different from the new one
            if [ "$currentNetBIOSName" != "$newcomputerName" ]; then
                echo "Updating NetBIOS name to $newcomputerName"
                defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server.plist NetBIOSName "$newcomputerName" > /dev/null 2>&1
            else
                echo "NetBIOS name is already set to $newcomputerName, no changes needed."
            fi

            /usr/local/bin/jamf setComputerName -name "$newcomputerName"
        else
            echo "Hostname already matches '$oldcomputername', no changes needed, exiting."
        fi
    }

    validation_check
    exit
fi
