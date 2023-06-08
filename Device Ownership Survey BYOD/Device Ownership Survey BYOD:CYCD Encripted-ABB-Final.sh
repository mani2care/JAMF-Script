#!/bin/bash

# Installs Rosetta will attempt to download the pkg from apple server and install it.
# Created By: Manikandan @mani2care
# On: 05-Jun-2023

# This script will call the jamfHelper to prompt a user to select between BYOD and CYCD.
# The Parameters will be set in the Policy.

# create the extension attribute from jamf and keep the extension name in handy with ID
# $4 API apiUser Encrypted String
# $5 API apiUser Salt
# $6 API apiUser Passphrase

# https://github.com/brysontyrrell/EncryptedStrings
# $7 API apiPass Encrypted String
# $8 API apiUser Salt
# $9 API apiPass Passphrase

# Find the details like this https://jamfurl:8443/computerExtensionAttributes.html?id=27&o=r

# $10 is your computerExtensionAttributes name
# $11 is your computerExtensionAttributes ID

# Set Parameter if you want to "Window Type". Note: Your choices include utility, hud, or fs
windowType="utility"

# Set Parameter if you want to "Logo". Note: This can be BASE64, a Local File, or a URL. If it's a URL, the file needs to be curl'd down prior to using jamfHelper.
icon="/Users/Shared/ABB.png"
defaultIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/UserIcon.icns"

# Check if the specified icon exists, otherwise use the default icon
if [ ! -f "$icon" ]; then
  icon="$defaultIcon"
fi

# icon size
iconSize="140" 

# Positions window in the upper right, upper left, lower right, or lower left of the user's screen
windowPosition="ur" # [ ur | ul | lr | ll ]

# Set Parameter if you want to "Window Title"
title="Employee Survey"

# Set Parameter if you want to "Window Heading"
heading="ABB Asset Declaration"

# Set Parameter if you want to "Window Message"
description="This survey is to determine the ownership of this Mac device. This information is required for inventory management purposes and to ensure security and compliance.

Please select your device type:

BYOD (Personally Owned \Other Organisation Owned)
CYCD (Company Owned Device)"

# Set Parameter if you want to "Button1"
button1="Personal"

# Set Parameter if you want to "Button2"
button2="Corporate"

# This will set a variable for the jamfHelper
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

# Function to display the dialog popup and retrieve user's choice
display_dialog() {
  userChoice=$("$jamfHelper" \
    -windowType "${windowType}" \
    -windowPosition "${windowPosition}" \
    -icon "${icon}" \
    -iconSize "${iconSize}" \
    -title "${title}" \
    -heading "${heading}" \
    -description "${description}" \
    -button1 "${button1}" \
    -button2 "${button2}" \
    -aligndescription left \
    -alignheading center)
  #echo "$userChoice"
  
  if [ "$userChoice" == "0" ]; then
    echo "User selected $button1"
    selectedOption1="$button1"
  elif [ "$userChoice" == "2" ]; then
    echo "User selected $button2"
    selectedOption1="$button2"
  elif [ "$userChoice" == "239" ]; then
    echo "User killed the display_dialog"
  fi
}
# Call the display_dialog function
display_dialog

# Loop until the user does not select "User killing the display_dialog" (userChoice != 239)
while [[ "$userChoice" == "239" ]]; do
  display_dialog
done

function apiUser1() {
    echo "${1}" | /usr/bin/openssl enc -aes256 -md md5 -d -a -A -S "${2}" -k "${3}"
}

function apiPass1() {
    echo "${1}" | /usr/bin/openssl enc -aes256 -md md5 -d -a -A -S "${2}" -k "${3}"
}

# Fetch the existing extension attribute inventory value
apiUser=$(apiUser1 "$4" "$5" "$6") # API user ID 
apiPass=$(apiPass1 "$7" "$8" "$9") # API Password ID

apiURL=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed 's|/$||')
udid=$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk '/Hardware UUID:/ { print $3 }')
eaName=""Device_Ownership"" # $10 is your computerExtensionAttributes name
eaID=""43"" # $11 is your computerExtensionAttributes ID

extensionOutput=$(curl -s -f -u $apiUser:$apiPass -H "Accept: application/xml" $apiURL/JSSResource/computers/udid/$udid/subset/extension_attributes | xpath -e "//extension_attribute[id=$eaID]" 2>&1 | awk -F'<value>|</value>' '{print $2}' | tail -n +1)

echo "Extension attribute value was: $extensionOutput"

if [[ "$extensionOutput" == "$selectedOption1" ]]; then
  echo "$selectedOption1 already exists. No need to update again."
  exit 0 > /dev/null
else
  # Update the inventory for BYOD devices
  if [[ "$selectedOption1" == "$button1" ]]; then
    echo "$selectedOption1 Owned device needs to be updated in the extension attribute"
    # Update the inventory for BYOD devices
    updateBYOD=$(curl -s -u "$apiUser:$apiPass" -X PUT -H "Content-Type: application/xml" -d "<computer><extension_attributes><extension_attribute><name>$eaName</name><value>$selectedOption1</value></extension_attribute></extension_attributes></computer>" "$apiURL/JSSResource/computers/udid/$udid")
    # Display success message
    echo "Inventory updated as $selectedOption1."
  fi
  # Update the inventory for CYCD devices
  if [[ "$selectedOption1" == "$button2" ]]; then
    echo "$selectedOption1 Owned device needs to be updated in the extension attribute"
    # Update the inventory for CYCD devices
    updateCYCD=$(curl -s -u "$apiUser:$apiPass" -X PUT -H "Content-Type: application/xml" -d "<computer><extension_attributes><extension_attribute><name>$eaName</name><value>$selectedOption1</value></extension_attribute></extension_attributes></computer>" "$apiURL/JSSResource/computers/udid/$udid")
    # Display success message
    echo "Inventory updated as $selectedOption1."
  fi

  # Fetch the updated extension attribute value
  updatedExtensionOutput=$(curl -s -f -u $apiUser:$apiPass -H "Accept: application/xml" $apiURL/JSSResource/computers/udid/$udid/subset/extension_attributes | xpath -e "//extension_attribute[id=$eaID]" 2>&1 | awk -F'<value>|</value>' '{print $2}' | tail -n +1)

  if [[ "$updatedExtensionOutput" == "$selectedOption1" ]]; then
    echo "Extension attribute value successfully updated to: $updatedExtensionOutput"
  else
    echo "Failed to update extension attribute value. Current value: $updatedExtensionOutput"
  fi
fi

exit 0