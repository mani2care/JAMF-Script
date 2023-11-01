#!/bin/zsh
###############################################################################
###############################################################################
# Remove A Mac From A Static Group - Prompt For Group And Serial.sh
###############################################################################
###############################################################################
#
# This script leverages bash, the Jamf API, and bearer token authentication.
#
# A script to allow users without Jamf admin access to remove Macs from
# static groups using a Self Service Policy, by selecting the static group from a list,
# then entering the target Mac's serial number.
#
# The script will attempt to remove the Mac from the selected group, then displays
# a dialog to the user informing them of it's success or HTTP error code received when
# attempting to interact with the Jamf API.
# 
# The script will attempt to login to whichever JSS server the Mac calling the policy is enrolled in,
# using credentials defined by $4 and $5.
# If you manage multiple JSS instances, it may be more prudent to define this via policy/script
# variable $6.
#
###############################################################################
# API User Permission Requirements:
# Smart Computer Groups - Read
# Static Computer Groups - Read, Modify
#
##############################################################################
##############################################################################
# Suggested Jamf Policy Option Labels
#
# $4 - Jamf API Username:
# $5 - Jamf API Password:
# $6 - Jamf Server Address (optional) - Enter address without trailing / - Example: https://jamfserver.jamfcloud.com
##############################################################################
##############################################################################
############################## Define Variables ##############################
##############################################################################
## Check if the variables have been provided and prompt for them if missing
# If a JSS URL is not provided, the script will use the address the system it's executing on
# is enrolled with.
apiUser="$4"
if [[ -z $apiUser ]]; then
	read -p "Username:" apiUser
fi
apiPass="$5"
if [[ -z $apiPass ]]; then
	read -sp "Password:" apiPass
fi
jssHost="$6"
if [[ -z $jssHost ]]; then
	jssHost=$( /usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url )
	else
	jssHost="$6"
fi
#
#
# created base64-encoded credentials
encodedCredentials=$( printf "$apiUser:$apiPass" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )
#
# generate an auth token
authToken=$( /usr/bin/curl $jssHost"uapi/auth/tokens" \
-s \
-X POST \
-H "Authorization: Basic $encodedCredentials" )
#
# parse authToken for token, omit expiration
token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "$authToken" | /usr/bin/xargs )
#
#
httpCodes="200 Request successful
201 Request to create or update object successful
400 Bad request
401 Authentication failed
403 Invalid permissions
404 Object/resource not found
409 Conflict
500 Internal server error"
#
##############################################################################
############################### Run Functions ################################
##############################################################################
#
# get list of static groups
computerGroupXML=$( /usr/bin/curl $jssHost"JSSResource/computergroups" \
	-s \
	-X GET \
    -H "Authorization: Bearer $token" \
    -H 'Accept: text/xml' )
#
##############################################################################
#
# Parse the XML for static groups only
staticGroupList=$( /usr/bin/xpath -e "//is_smart[text()='false']/preceding-sibling::name/text()" 2>&1 <<< "$computerGroupXML" | /usr/bin/sed 's/-- NODE --//g;' | /usr/bin/tail -n +3 | sed -e '/^[[:blank:]]*$/d' | /usr/bin/sort )
#
# Display a dialog to choose a group and endcode for HTTP submission
pickTheGroup="choose from list every paragraph of \"$staticGroupList\" with title \"Select The Group To Modify\" with prompt \"Choose ONE group to remove a Mac from...\" multiple selections allowed false empty selection allowed false"
#
staticGroupName=$( /usr/bin/osascript -e "$pickTheGroup" | /usr/bin/sed -e 's/ /%20/g' )
#
# display dialog to prompt for the target Mac's serial number
gatherSerial="display dialog \"Enter target the Mac's serial number:\" default answer \"\" with title \"Define The Mac To Remove\" buttons {\"Cancel\", \"OK\"} default button {\"OK\"}"
#
results=$( /usr/bin/osascript -e "$gatherSerial" )
serialNumber=$( echo "$results" | /usr/bin/awk -F "text returned:" '{print $2}' )
#
##############################################################################
#
# Set XML data to remove Mac from group by serial number
apiDataDeleteFromGroup="<computer_group><computer_deletions><computer><serial_number>"$serialNumber"</serial_number></computer></computer_deletions></computer_group>"
#
## curl call to the API to Remove the Mac to the provided group ID by doing a PUT of the 
deleteComputer=$( curl \
	-s \
	-f \
    -w "%{http_code}" \
	-X PUT \
    -H "Authorization: Bearer $token" \
    -H 'Accept: application/json' \
	-H "Content-Type: text/xml" \
	-d "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>${apiDataDeleteFromGroup}" $jssHost"JSSResource/computergroups/name/"$staticGroupName )
##############################################################################
##############################################################################
##############################################################################
#
# Evaluate HTTP status code from curl attempt
resultStatus=${deleteComputer: -3}
code=$( /usr/bin/grep "$resultStatus" <<< "$httpCodes" )
#
# Expire the Auth Token since we're done with it
expireToken=$( /usr/bin/curl $jssHost"uapi/auth/invalidateToken" \
	-s \
	-X POST \
	-H "Authorization: Bearer $token" )
#
$expireToken
#
# Display status dialog based on HTTP status code
if [ "$code" = "201 Request to create or update object successful" ]; 
	then
		displayResults="display dialog \"$serialNumber was removed from the static group successfully\" with title \"Mac Successfully Removed From Group\" buttons {\"OK\"} default button {\"OK\"}"
		/usr/bin/osascript -e "$displayResults"
		exit 0
	else
		displayResults="display dialog \"Error Modifying Group: $code\" with title \"Error Modifying Group\" buttons {\"OK\"} default button {\"OK\"}"
		/usr/bin/osascript -e "$displayResults"
fi
#
exit 0
