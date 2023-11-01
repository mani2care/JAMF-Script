#!/bin/zsh
#######################################################################
######################################################################
# Add A Mac To A Static Group Via Self Service Prompt For Serial Number
# via self service.
# Uses Bearer Token Authentication To The JSS
#
############## Define Variable Block #################################
######################################################################
## Check if the variables have been provided, ask for them if not
apiUser="$4"
if [[ -z $apiUser ]]; then
	read -p "Username:" apiUser
fi
apiPass="$5"
if [[ -z $apiPass ]]; then
	read -sp "Password:" apiPass
fi
groupID="$6"
if [[ -z $groupID ]]; then
	read -p "Group ID Number:" groupID
fi
#
# Find system's JSS URL
jssHost=$( /usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url )

# created base64-encoded credentials
encodedCredentials=$( printf "$apiUser:$apiPass" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

# generate an auth token
authToken=$( /usr/bin/curl "$jssHost/uapi/auth/tokens" \
-s \
-X POST \
-H "Authorization: Basic $encodedCredentials" )

# parse authToken for token, omit expiration
token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "$authToken" | /usr/bin/xargs )
serialNumberCheck="/tmp/JamfAPI/jpsStaticGroupSerialCheck.txt"
filePath="/tmp/JamfAPI/"
loop="Continue"
oops1Dialog="SORRY! Either the Serial Number entered: "
oops2Dialog=" was incorrect or that device is not currently being managed by Jamf Pro. Please check the Mac's serial number and try again."
addAnotherDialog="Would you like to add another Mac?"
mainDialog="Please Enter the Serial Number of the Mac to add to the "$groupName" Group (format: XX123456)"
appTitle="Add computer to the Static Group "$groupName""
xmlContentType="Content-Type: application/xml"
computersAPI="JSSResource/computers"
computerIDAPI="/JSSResource/computergroups/id/"
apiDataAddToGroup="<computer_group><id>${targetGroupID}</id></computer_group>"

######################################################################
################# Define Functions Block #############################
######################################################################

file_Check() {
mkdir -p "$filePath"
if [ -f "$serialNumberCheck" ]
then
rm -rf "$serialNumberCheck"
fi
}

get_List() {
curl \
	-s $jssHost"JSSResource/computers" \
    -H 'Accept: application/xml' \
	-H "Authorization: Bearer $token" \
	 > "$serialNumberCheck"
}

add_Devices() {
serialNumber=$(osascript <<EOT
tell app "System Events"
text returned of (display dialog "${mainDialog}" buttons {"Cancel", "Continue"} default button "Continue" default answer "" with title "${appTitle}")
end tell
EOT
)
if ! grep -i ${serialNumber} "$serialNumberCheck"
	then
		osascript <<EOT
		tell app "System Events"
		display dialog "${oops1Dialog} ${serialNumber} ${oops2Dialog}" buttons {"Done"} default button "Done" with title "${appTitle}"
		end tell
EOT
	else
		#Add computer to group by ID
		## the location in the API URL to remove the computer by serial number	
		## curl call to the API to add the computer to the provided group ID
apiData="<computer_group><computer_additions><computer><serial_number>"$serialNumber"</serial_number></computer></computer_additions></computer_group>"
curl \
	-s \
	-f \
	-X PUT \
    -H "Authorization: Bearer $token" \
    -H 'Accept: application/json' \
	-H "Content-Type: text/xml" \
	-d "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>$apiData" $jssHost"JSSResource/computergroups/id/"$groupID
fi
}

device_Loop() {
loop=$(osascript <<EOT
tell app "System Events"
button returned of (display dialog "${addAnotherDialog}" buttons {"Cancel", "Continue", "Done" } default button "Done" with title "${appTitle}")
end tell
EOT
)
}
######################################################################
################# Script Run Block ###################################
######################################################################
while [ "${loop}" = "Continue" ]
do
file_Check
get_List
add_Devices
device_Loop
file_Check
done
