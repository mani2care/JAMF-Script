#!/bin/bash

# By Manikandan (mani2care)
# Purpose: Cleanup Workplace Join (WPJ) and jamfAAD artifacts from macOS

#-----------------------------#
# ✅ Setup & Logging
#-----------------------------#
# Get the currently logged-in user and UID
loggedInUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && !/loginwindow/ { print $3 }')
loggedInUID=$(id -u "$loggedInUser")

#-----------------------------#
# ✅ Get AAD cert SHA-1
#-----------------------------#
certDump=$(/bin/launchctl asuser "$loggedInUID" sudo -iu "$loggedInUser" security find-certificate -a -Z 2>/dev/null)

# Extract the SHA-1 of the target cert
AAD_ID=$(echo "$certDump" | grep -B 9 "MS-ORGANIZATION-ACCESS" | grep "SHA-1" | awk '{print $3}')

#-----------------------------#
# ✅ Quit Company Portal (if open)
#-----------------------------#
if [[ $(pgrep "Company Portal") != "" ]]; then
  echo "Quitting Company Portal"
  killall "Company Portal"
fi

#-----------------------------#
# ✅ File & App Cleanup
#-----------------------------#
file_Array=(
  "/Applications/Company Portal.app"
  "/Users/$loggedInUser/Library/Preferences/com.jamf.management.jamfAAD.plist"
  "/Users/$loggedInUser/Library/Preferences/com.microsoft.CompanyPortalMac.plist"
  "/Users/$loggedInUser/Library/Application Support/com.microsoft.CompanyPortal.usercontext.info"
  "/Users/$loggedInUser/Library/Application Support/com.jamfsoftware.selfservice.mac"
  "/Users/$loggedInUser/Library/Application Support/com.microsoft.CompanyPortalMac"
  "/Users/$loggedInUser/Library/Saved Application State/com.jamfsoftware.selfservice.mac.savedState"
  "/Users/$loggedInUser/Library/Saved Application State/com.jamf.management.jamfAAD.savedState"
  "/Users/$loggedInUser/Library/Saved Application State/com.microsoft.CompanyPortal.savedState"
  "/Users/$loggedInUser/Library/Saved Application State/com.microsoft.CompanyPortalMac.savedState"
  "/Users/$loggedInUser/Library/Preferences/com.microsoft.CompanyPortal.plist"
  "/Users/$loggedInUser/Library/Preferences/com.jamfsoftware.management.jamfAAD.plist"
  "/Users/$loggedInUser/Library/Cookies/com.microsoft.CompanyPortal.binarycookies"
  "/Users/$loggedInUser/Library/Cookies/com.microsoft.CompanyPortalMac.binarycookies"
  "/Users/$loggedInUser/Library/Cookies/com.jamf.management.jamfAAD.binarycookies"
)

for i in "${file_Array[@]}"; do
  if [[ -e "$i" ]]; then
    echo "Deleting: $i"
    rm -rf "$i"
  fi
done

/usr/sbin/pkgutil --forget com.microsoft.CompanyPortalMac 2>/dev/null

#-----------------------------#
# ✅ Delete AAD certificate
#-----------------------------#
if [[ -n "$AAD_ID" ]]; then
    echo "Found MS-ORGANIZATION-ACCESS cert with SHA-1: $AAD_ID"
    
    # Delete the identity from user's login keychain using launchctl asuser
    /bin/launchctl asuser "$loggedInUID" sudo -iu "$loggedInUser" /usr/bin/security delete-identity -Z "$AAD_ID" /Users/"$loggedInUser"/Library/Keychains/login.keychain-db > /dev/null 2>&1

    if [[ $? -eq 0 ]]; then
        echo "✅ Certificate deleted successfully."
    else
        echo "⚠️ Failed to delete certificate."
    fi
else
    echo "❌ MS-ORGANIZATION-ACCESS certificate not found."
fi

#-----------------------------#
# ✅ Run user-level keychain cleanup
#-----------------------------#
/bin/launchctl asuser "$loggedInUID" sudo -iu "$loggedInUser" /bin/bash <<'USER_SCRIPT'

# Password item keys
passwordItemAccounts_Array=(
  'com.microsoft.workplacejoin.thumbprint'
  'com.microsoft.workplacejoin.registeredUserPrincipalName'
  'com.microsoft.workplacejoin.deviceName'
  'com.microsoft.workplacejoin.deviceOSVersion'
  'com.microsoft.workplacejoin.discoveryHint'
)

# Delete each matching password item
for i in "${passwordItemAccounts_Array[@]}"; do
  if /usr/bin/security find-generic-password -a "$i" >/dev/null 2>&1; then
    echo "🗑️  Deleting password item: $i"
    /usr/bin/security delete-generic-password -a "$i" >/dev/null 2>&1
  fi
done

# Delete all matching 'devicePatchAttemptTimestamp' items
while /usr/bin/security find-generic-password -a 'com.microsoft.workplacejoin.devicePatchAttemptTimestamp' >/dev/null 2>&1; do
  echo "🗑️  Deleting: com.microsoft.workplacejoin.devicePatchAttemptTimestamp"
  /usr/bin/security delete-generic-password -a 'com.microsoft.workplacejoin.devicePatchAttemptTimestamp' >/dev/null 2>&1
done

# Identity preference labels
identityPref_Array=(
  'com.jamf.management.jamfAAD'
  'com.microsoft.CompanyPortal.enrollment'
  'com.microsoft.CompanyPortal'
  'com.microsoft.CompanyPortal.HockeySDK'
  'com.microsoft.adalcache'
  'enterpriseregistration.windows.net'
  'https://device.login.microsoftonline.com (UBF8T346G9.com.microsoft.CompanyPortalMac)'
  'https://device.login.microsoftonline.com/ (UBF8T346G9.com.microsoft.CompanyPortalMac)'
  'https://enterpriseregistration.windows.net (UBF8T346G9.com.microsoft.CompanyPortalMac)'
  'https://enterpriseregistration.windows.net/ (UBF8T346G9.com.microsoft.CompanyPortalMac)'
)

# Delete identity preference items
for i in "${identityPref_Array[@]}"; do
  if /usr/bin/security find-generic-password -l "$i" >/dev/null 2>&1; then
    echo "🗑️  Deleting identity preference: $i"
    /usr/bin/security delete-generic-password -l "$i" >/dev/null 2>&1
  fi
done

echo "✅ Cleanup complete."

USER_SCRIPT


exit 0
