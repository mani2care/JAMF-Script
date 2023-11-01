#!/bin/zsh
# Add a computer to a static group by its ID with the Jamf API
# Using script parameters $4, $5, $6 as reccomended by https://www.jamf.com/jamf-nation/articles/146/script-parameters
# also works interactively for testing

## Grab the serial number of the device
serialNumber="$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')"

## Check if the variables have been provided, ask for them if not
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
	read -p "JSS Host Address:" jssHost
fi
groupID="$7"
if [[ -z $groupID ]]; then
	read -p "Group ID Number:" groupID
fi

# created base64-encoded credentials
encodedCredentials=$( printf "$apiUser:$apiPass" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

# generate an auth token
authToken=$( /usr/bin/curl "$jssHost/uapi/auth/tokens" \
-s \
-X POST \
-H "Authorization: Basic $encodedCredentials" )

# parse authToken for token, omit expiration
token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "$authToken" | /usr/bin/xargs )

## the location in the API URL to add the computer by serial number
apiData="<computer_group><computer_deletions><computer><serial_number>${serialNumber}</serial_number></computer></computer_deletions></computer_group>"

## curl call to the API to add the computer to the provided group ID
curl \
	-s \
	-f \
	-X PUT \
    -H "Authorization: Bearer $token" \
    -H 'Accept: application/json' \
	-H "Content-Type: text/xml" \
	-d "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>${apiData}" ${jssHost}/JSSResource/computergroups/id/${groupID}
    
# expire the auth token
/usr/bin/curl "$jssHost/uapi/auth/invalidateToken" \
	-s \
	-X POST \
	-H "Authorization: Bearer $token"
