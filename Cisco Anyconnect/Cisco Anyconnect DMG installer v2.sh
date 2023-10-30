#!/bin/sh
#
#########################
# Created by mikeg
#
# This script installs a cached Anyconnect DMG on a Mac by mounting the
# DMG running the pkg inside with the choices XML, unmounting and deleting the DMG,
# and remove the uninstaller after.
#
# Parameter 5 is the Mounted DMG name as it's different than parameter 4
#
# This script can be modified to be used with other DMG's
#
# Script does not contain a Jamf recon command as it's designed
# to be run in the enrollment.
#
##### History #####
#
# v1.1 Nov 28 2022 - mikeg
# Updated to use parameters instead of hard coded names
#
# v1.0 Jul 12 2022 - mikeg
# Created script
#
#########################
#

# Gets DMG name from Parameter 4 in Jamf policy
InstallerLocation="/Library/Application Support/JAMF/Waiting Room/$4"
echo "$InstallerLocation"

# Attach dmg
hdiutil attach "$InstallerLocation" -nobrowse
echo "Attached DMG"

# Installs Cisco AnyConnect
# Parameter 5 is the Mounted DMG name as it's different tha parameter 4
installer -applyChoiceChangesXML "/Volumes/$5/vpn_install_choices.xml" -pkg "/Volumes/$5/AnyConnect.pkg" -target /

echo "Installed Cisco AnyConnect"

# Unmount DMG
hdiutil detach "/Volumes/$5"
echo "Unmounted DMG"

# Delete DMG
rm "$InstallerLocation"
echo "Deleted DMG"

# OPTIONAL Deletes uninstallers - required by our security group
# rm -rf /Applications/Cisco/Uninstall\ AnyConnect.app
# rm -rf /Applications/Cisco/Uninstall\ AnyConnect\ DART.app

open "/Applications/Cisco/Cisco AnyConnect Secure Mobility Client.app"

exit 0
