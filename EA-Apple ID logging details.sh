#!/bin/bash

loggedInUser=$(stat -f "%Su" /dev/console)

sudo -u "$loggedInUser" /bin/bash <<'EOF'
plistFile=~/Library/Preferences/MobileMeAccounts.plist

if [ ! -f "$plistFile" ]; then
    echo "<result>No Apple ID found</result>"
    exit 0
fi

AppleID=$(/usr/libexec/PlistBuddy -c "Print :Accounts:0:AccountID" "$plistFile" 2>/dev/null)
ManagedCheck=$(/usr/libexec/PlistBuddy -c "Print :Accounts:0:isManagedAppleID" "$plistFile" 2>/dev/null)

if [[ -z "$AppleID" ]]; then
    echo "<result>No_Apple_ID_found</result>"
elif [[ "$ManagedCheck" == "true" ]]; then
    echo "<result>Managed_Apple_ID: $AppleID</result>"
elif [[ "$ManagedCheck" == "false" ]]; then
    echo "<result>Personal_Apple_ID: $AppleID</result>"
else
    echo "<result>Apple ID: $AppleID (Managed status unknown)</result>"
fi
EOF
