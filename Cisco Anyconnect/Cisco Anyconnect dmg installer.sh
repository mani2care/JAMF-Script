#!/bin/sh
#
#########################
# Created by @mikeg of MacAdmins
#
# This script is designed for use with Jamf Pro but can work with other MDM's.
# It installs Cisco Secure Client for macOS by moving the cached unmodified
# pre-deploy DMG to a temporary directory, converting it to a read/write DMG,
# then deleting/moving the required files for the installer into the new DMG,
# converting back to read only, then moving it back to the waiting room,
# running the installer, then unmounting the DMG, deleting it, then deleting
# the uninstallers for Cisco Secure Client and DART.
#
# Parameter 5 in Jamf is the Mounted DMG name as it's different tha parameter 4
# verify before deploying and adjust parameters as needed.
#
# This script can be modified to be used with other DMG's
#
# Script does not contain a Jamf recon command as it's designed
# to be run in the enrollment.
#
##### Acknowledgements #####
#
# Thank you to @Fraser on the MacAdmins slack for sharing part of your script!
# Used the DMG in line conversion to cut down on manual work.
#
##### History #####
#
# v2.0 OCT 26 2023 - mikeg
# Cisco Secure Client v5 removed the auto update feature,
# so hand making new dmgs is not sustainable.
#
# I use seperate Jamf policies to create the choices file and the OrgInfo.json
# as they maybe different or need to be updated more frequently.
#
# Those policies are just scripts with the following which could be added in script.
#
# CiscoFILES='your OrgInfo.json or choices text between single quotes'
# echo "$DATA" > "/Library/Application Support/JAMF/Waiting Room/FILENAME"
#
# Sleeps are added to give the computer a second to catch up, without them issues
# seemed to happen. Not a lot of time added so not a worry.
#
# v1.0 AUG 7 2023 - mikeg
# Created script
#
#########################
#

### Variables ###
# Where is the original DMG stored
WaitingRoomDMG="/Library/Application Support/JAMF/Waiting Room/$4"
# Temp directory for this script
tmplocation="/tmp/CiscoInstaller"
# Temp location of  dmg
tmpDMGLocation="/tmp/CiscoInstaller/$4"
# Name of read-write dmg
tmprwDMGLocation="/tmp/CiscoInstaller/$4-rw.dmg"
# New DMG location
NewDMGLocation="/tmp/CiscoInstaller/New/$4"



# ACTransformations file to hide the AnyConnect VPN portion
HideVPNGUI='<!-- Optional AnyConnect installer settings are provided below. Uncomment the setting(s) to perform optional action(s) at install time.  -->
<Transforms>
<DisableVPN>true</DisableVPN> -->
<DisableCustomerExperienceFeedback>true</DisableCustomerExperienceFeedback> -->
</Transforms>
'

# echos to show the locations are right in Jamf policy details
echo "$WaitingRoomDMG"
echo "$tmpDMGLocation"
echo "$tmprwDMGLocation"

mkdir "/tmp/CiscoInstaller/"
mkdir "/tmp/CiscoInstaller/New/"
chmod 777 "/tmp/CiscoInstaller/"
chmod 777 "/tmp/CiscoInstaller/New/"

# Move DMG to temp space
mv "$WaitingRoomDMG" "/tmp/CiscoInstaller/"

# Make a read-write disk image
/usr/bin/hdiutil convert "$tmpDMGLocation" -format UDRW -o "$tmprwDMGLocation"
echo "Converted DMG"

rm "$tmpDMGLocation"

# Attach dmg
hdiutil attach "$tmprwDMGLocation" -nobrowse
echo "Attached R-W DMG"

wait 5

# Delete old ACTransformations.xml file
# If you are not using the VPN function, it can be hidden from the GUI
# If you are using the VPN
rm -rf "/Volumes/$5/Profiles/ACTransforms.xml"
echo "Deleted ACTransforms.xml file"

# Creates new ACTransforms.xml file
echo "$HideVPNGUI" > "/Library/Application Support/JAMF/Waiting Room/ACTransforms.xml"

# Call Jamf policy to create choices file and OrgInfo.json in waiting room
jamf policy -event CiscoChoices
jamf policy -event CiscoJSON
echo "Cisco required configs created"

# Moves OrgInfo.json, ACTransforms.xml installer choices file into the Read/Write DMG
mv "/Library/Application Support/JAMF/Waiting Room/CiscoChoices.xml" "/Volumes/$5"
mv "/Library/Application Support/JAMF/Waiting Room/OrgInfo.json" "/Volumes/$5/Profiles/umbrella"
mv "/Library/Application Support/JAMF/Waiting Room/ACTransforms.xml" "/Volumes/$5/Profiles/"

echo "Files moved to required locations"

# Unmounts Read Write DMG
hdiutil detach "/Volumes/$5"

# Converts back to read only
/usr/bin/hdiutil convert "$tmprwDMGLocation" -format UDZO -o "$NewDMGLocation"

# Moves back to waiting room for Jamf
mv "$NewDMGLocation" "/Library/Application Support/JAMF/Waiting Room/"

# Added sleep to allow computer to catch up
sleep 5

# Attach modified read only dmg
hdiutil attach "$WaitingRoomDMG" -nobrowse

# Added sleep to allow computer to catch up
sleep 5

# Installs Cisco AnyConnect
installer -applyChoiceChangesXML "/Volumes/$5/CiscoChoices.xml" -pkg "/Volumes/$5/Cisco Secure Client.pkg" -target /
echo "Installed Cisco Secure Client"

sleep 15

# Unmount Read-Write DMG
hdiutil detach "/Volumes/$5"
echo "Unmounted DMG"

sleep 5

# Delete DMGs
rm "$WaitingRoomDMG"
echo "Deleted DMG from Waiting Room"

# Deletes uninstallers this can be commented out if you want to leave them
rm -rf "/Applications/Cisco/Uninstall Cisco Secure Client.app"
rm -rf "/Applications/Cisco/Uninstall Cisco Secure Client - DART.app"

# Deletes temp folder
rm -rf "/tmp/CiscoInstaller/"

# Opens the app to ensure it's on the menu bar
open "/Applications/Cisco/Cisco Secure Client.app"

exit 0
