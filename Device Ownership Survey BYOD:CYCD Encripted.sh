#!/bin/bash

# Installs Rosetta will attempt to download the pkg from apple server and install it.
# Created By : Manikandan @mani2care
# On : 05-Jun-2023

# This script will call the jamfHelper to prompt a user to select between BYOD and CYCD.
# The Parameters will be set in the Policy.

# create the extension attribute from jamf and keep the extension name in handy with ID
# $4 API apiUser Encrypted String
# $5 API apiUser Salt
# $6 API apiUser Passphrase

#https://github.com/brysontyrrell/EncryptedStrings
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

# Set Parameter if you want to "Window Title"
title="Employee Survey"

# Set Parameter if you want to "Window Heading"
heading="ABB Device Survey"

# Set Parameter if you want to "Window Message"
description="This survey is conducted to gather information about the devices being used by employees in order to improve IT asset management, ensure security and compliance, allocate resources effectively, enhance user experience and productivity, enforce relevant policies, and plan for the future. 

Please select your device type:

	BYOD (if you have Personally/Other Organisation Owned)
	CYCD (if you have ABB Owned device)"

# Set Parameter if you want to "Button1"
button1="BYOD"

# Set Parameter if you want to "Button2"
button2="CYCD"

# This will set a variable for the jamfHelper
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

# Function to display the dialog popup and retrieve user's choice
display_dialog() {
  userChoice=$("$jamfHelper" -windowType "$windowType" -icon "$icon" -title "$title" -heading "$heading" -description "$description" -button1 "$button1" -button2 "$button2" -aligndescription left -alignheading center )
  #echo "$userChoice"
  
  if [ "$userChoice" == "0" ]; then
    echo "BYOD selected"
    selectedOption1="BYOD"
  elif [ "$userChoice" == "2" ]; then
    echo "CYCD selected"
    selectedOption1="CYCD"
  elif [ "$userChoice" == "239" ]; then
    echo "User killing the display_dialog"
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
eaName=""Device_Ownership"" #$10 is your computerExtensionAttributes name
eaID=""43"" #$11 is your computerExtensionAttributes ID

extensionoutput=$(curl -s -f -u $apiUser:$apiPass -H "Accept: application/xml" $apiURL/JSSResource/computers/udid/$udid/subset/extension_attributes | xpath -e "//extension_attribute[id=$eaID]" 2>&1 | awk -F'<value>|</value>' '{print $2}' | tail -n +1)

echo "Extension attribute value was: $extensionoutput"

if [[ "$extensionoutput" == "$selectedOption1" ]]; then
  echo "$selectedOption1 already exists. No need to update again."
  exit 0
else
  # Check the selected option and update the inventory accordingly
  if [[ "$selectedOption1" == "$button1" ]]; then
    echo "$selectedOption1 needs to be updated in the extension attribute"
    # Update the inventory for BYOD devices
    updateBYOD=$(curl -s -u "$apiUser:$apiPass" -X PUT -H "Content-Type: application/xml" -d "<computer><extension_attributes><extension_attribute><name>$eaName</name><value>$selectedOption1</value></extension_attribute></extension_attributes></computer>" "$apiURL/JSSResource/computers/udid/$udid")
    # Display success message
    echo "Inventory updated as $selectedOption1."
  elif [[ "$selectedOption1" == "$button2" ]]; then
    echo "$selectedOption1 needs to be updated in the extension attribute"
    # Update the inventory for CYCD devices
    updateCYCD=$(curl -s -u "$apiUser:$apiPass" -X PUT -H "Content-Type: application/xml" -d "<computer><extension_attributes><extension_attribute><name>$eaName</name><value>$selectedOption1</value></extension_attribute></extension_attributes></computer>" "$apiURL/JSSResource/computers/udid/$udid")
    # Display success message
    echo "Inventory updated as $selectedOption1."
  fi
fi