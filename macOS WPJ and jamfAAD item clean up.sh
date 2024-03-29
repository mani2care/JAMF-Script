#!/bin/bash
#macOS WPJ and jamfAAD item clean up
#
#This script will remove the Workplace Join items made by Company Portal durring a device registration. It will also clear the jamfAAD items from the gatherAADInfo command run after a sucessful WPJ
#Clearing this data will allow for a re-registration devices side.
#
#NOTE: THIS SCRIPT WILL NOT CLEAR AZURE AD RECORDS (those are created by Company Portal). IT MAY CLEAR MEM RECORDS IF A JAMFAAD GATHER AAD INFO COMMAND RUNS AFTER THIS AS THE AAD ID IS NOW MISSING. THIS WILL RESULT IN A DEACTIVATION OF THE DEVICE RECORD SENT FROM JAMF PRO TO AAD (AND AAD TO MEM).
#
#variable to run as current user
currentuser=`stat -f "%Su" /dev/console`
#
#variable for current logged in user AAD ID cert. and WPJ key 
AAD_ID=$(su "$currentuser" -c "security find-certificate -a -Z | grep -B 9 "MS-ORGANIZATION-ACCESS" | awk '/\"alis\"<blob>=\"/ {print $NF}' | sed 's/  \"alis\"<blob>=\"//;s/.$//'")
#CERT_BY_SHA=$(su "$currentuser" -c "security find-certificate -a -Z | grep -B 9 "MS-ORGANIZATION-ACCESS" | grep "SHA-1" | awk '{print $3}'")
#
echo "Removing keychain password items for jamfAAD"
#jamfAAD items
su "$currentuser" -c "security delete-generic-password -l 'com.jamf.management.jamfAAD'"
rm -rf /Users/"$currentuser"/Library/Saved\ Application\ State/com.jamfsoftware.selfservice.mac.savedState
rm -r /Users/"$currentuser"/Library/Cookes/com.jamf.management.jamfAAD.binarycookies
rm -rf /Users/"$currentuser"/Library/Saved\ Application\ State/com.jamf.management.jamfAAD.savedState
su "$currentuser" -c "/Library/Application\ Support/JAMF/Jamf.app/Contents/MacOS/JamfAAD.app/Contents/MacOS/JamfAAD clean"
#
echo "Removing keychain password items for Company Portal app (v2.6 and higher with new com.microsoft.CompanyPortalMac bundle ID)"
#Company Portal app items
rm -r /Users/"$currentuser"/Library/Cookies/com.microsoft.CompanyPortalMac.binarycookies
rm -rf /Users/"$currentuser"/Library/Saved\ Application\ State/com.microsoft.CompanyPortalMac.savedState
rm -r /Users/"$currentuser"/Library/Preferences/com.microsoft.CompanyPortalMac.plist
rm -r /Library/Preferences/com.microsoft.CompanyPortalMac.plist
rm -rf /Users/"$currentuser"/Library/Application\ Support/com.microsoft.CompanyPortalMac
rm -rf /Users/"$currentuser"/Library/Application\ Support/com.microsoft.CompanyPortalMac.usercontext.info
su "$currentuser" -c "security delete-generic-password -l 'com.microsoft.CompanyPortal'"
su "$currentuser" -c "security delete-generic-password -l 'com.microsoft.CompanyPortalMac'"
su "$currentuser" -c "security delete-generic-password -l 'com.microsoft.CompanyPortal.HockeySDK'"
su "$currentuser" -c "security delete-generic-password -l 'com.microsoft.adalcache'"
su "$currentuser" -c "security delete-generic-password -l 'enterpriseregistration.windows.net'"
su "$currentuser" -c "security delete-generic-password -l 'https://device.login.microsoftonline.com'"
su "$currentuser" -c "security delete-generic-password -l 'https://device.login.microsoftonline.com/' "
su "$currentuser" -c "security delete-generic-password -l 'https://enterpriseregistration.windows.net' "
su "$currentuser" -c "security delete-generic-password -l 'https://enterpriseregistration.windows.net/' "
su "$currentuser" -c "security delete-generic-password -a 'com.microsoft.workplacejoin.thumbprint' "
su "$currentuser" -c "security delete-generic-password -a 'com.microsoft.workplacejoin.registeredUserPrincipalName' "
#
echo "Removing WPJ for Device AAD ID $AAD_ID for $currentuser"
su "$currentuser" -c "security delete-identity -c $AAD_ID"
#echo "Removing WPJ for Device AAD ID $AAD_ID for $currentuser from SHA hash $CERT_BY_HASH"
#
echo "Please REBOOT this macOS device to re-load the login.keychain and re-run the Azure Registration via Self Service AFTER you ensure device removal from AAD and MEM server side."
exit 0
