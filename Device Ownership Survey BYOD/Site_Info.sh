#!/bin/sh

# Check site_name in the global /Library/Managed Preferences/com.abb.deviceinfo.plist
siteName=$(/usr/libexec/PlistBuddy -c "Print :site_name" "/Library/Managed Preferences/com.abb.deviceinfo.plist" 2>/dev/null)

# If siteName is "BYOD" or "CYOD", output the result and exit
if [ "$siteName" = "BYOD" ] || [ "$siteName" = "CYOD" ]; then
    echo "<result>${siteName}</result>"
    exit 0
fi

# If not found in the global plist, try the profiles command
siteName=$(profiles -P -o stdout | grep -i -A 20 "User Info" | grep "site_name" | awk -F'=' '{gsub(/^ *| *$/,"",$2); print $2}' | tr -d ';' | tr -d '"' 2>/dev/null)

# If siteName is "BYOD" or "CYOD" from profiles, output the result and exit
if [ "$siteName" = "BYOD" ] || [ "$siteName" = "CYOD" ]; then
    echo "<result>${siteName}</result>"
    exit 0
fi

# If still not found, check each user's /Library/Managed Preferences/$USER/com.abb.deviceinfo.plist
for userDir in /Library/Managed\ Preferences/*; do
    userPlist="${userDir}/com.abb.deviceinfo.plist"
    if [ -f "$userPlist" ]; then
        siteName=$(/usr/libexec/PlistBuddy -c "Print :site_name" "$userPlist" 2>/dev/null)
        
        # If siteName is "BYOD" or "CYOD", output the result and exit
        if [ "$siteName" = "BYOD" ] || [ "$siteName" = "CYOD" ]; then
            echo "<result>${siteName}</result>"
            exit 0
        fi
    fi
done

# If no result found in any location, output Not_Available
echo "<result>Not_Available</result>"
