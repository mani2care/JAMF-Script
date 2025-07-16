#!/bin/bash
#Updated 07/11/2025 - Silent execution and error handling by Manikandan

# Get currently logged in user
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && !/loginwindow/ { print $3 }' )
if [[ -z "$loggedInUser" ]]; then
    echo "<result>No user logged in</result>"
    exit 0
fi

# Get user's home directory
userHome=$(dscl . -read "/Users/$loggedInUser" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
if [[ -z "$userHome" || ! -d "$userHome" ]]; then
    echo "<result>User home directory not found for $loggedInUser</result>"
    exit 0
fi

# Check Platform SSO registration
platformStatus=$(su -l "$loggedInUser" -c "app-sso platform -s 2>/dev/null" | grep 'registration' | awk '{print $3}' | sed 's/,//' 2>/dev/null)
if [[ "$platformStatus" == "true" ]]; then
    psso_AAD_ID=$(defaults read "$userHome/Library/Preferences/com.jamf.management.jamfAAD.plist" have_an_Azure_id 2>/dev/null)
    if [[ "$psso_AAD_ID" == "1" ]]; then
        echo "<result>Registered with Platform SSO - $userHome</result>"
        exit 0
    else
        echo "<result>Platform SSO registered but AAD ID not acquired for user home: $userHome</result>"
        exit 0
    fi
fi

# Check for WPJ key in login keychain
#WPJKey=$(su "$currentuser" -c "security find-certificate -a -Z | grep -B 9 "MS-ORGANIZATION-ACCESS" | awk '/\"alis\"<blob>=\"/ {print $NF}' | sed 's/  \"alis\"<blob>=\"//;s/.$//'")
# Check for WPJ key in login keychain
WPJKey=$(su -l "$loggedInUser" -c "security find-certificate -a -Z login.keychain-db | grep -B 9 'MS-ORGANIZATION-ACCESS' | awk '/\"alis\"<blob>=\"/ {print \$NF}' | sed 's/  \"alis\"<blob>=\"//;s/.\$//'")

#WPJKey=$(security dump "$userHome/Library/Keychains/login.keychain-db" 2>/dev/null | grep -i "MS-ORGANIZATION-ACCESS")
if [[ -n "$WPJKey" ]]; then
    plist="$userHome/Library/Preferences/com.jamf.management.jamfAAD.plist"
    if [[ ! -f "$plist" ]]; then
        echo "<result>WPJ Key present, JamfAAD PLIST missing from user home: $userHome</result>"
        exit 0
    fi

    AAD_ID=$(defaults read "$plist" have_an_Azure_id 2>/dev/null)
    if [[ "$AAD_ID" == "1" ]]; then
        echo "<result>Registered - $userHome</result>"
        exit 0
    else
        echo "<result>WPJ Key Present. AAD ID not acquired for user home: $userHome</result>"
        exit 0
    fi
fi

# No WPJ key
echo "<result>Not Registered for user home $userHome</result>"
