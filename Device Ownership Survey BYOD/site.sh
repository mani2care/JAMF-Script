#!/bin/sh

# Check if the username is present in /Library/Managed Preferences/com.abb.deviceinfo.plist
siteName=$(defaults read "/Library/Managed Preferences/com.abb.deviceinfo.plist" site_name 2>/dev/null)

if [ -n "$siteName" ]; then
    echo "<result>${siteName}</result>"
else
    # If not found in deviceinfo.plist, check using profiles command
    siteName=$(profiles -P -o stdout | grep -i -A 20 "User Info" | grep "site_name" | awk -F'=' '{gsub(/^ *| *$/,"",$2); print $2}' | tr -d ';' | tr -d '"' 2>/dev/null)
    
    if [ -n "$siteName" ]; then
        echo "<result>${siteName}</result>"
    else
        echo "<result>Not_Available</result>"
    fi
fi
