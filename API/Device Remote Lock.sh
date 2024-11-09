#!/bin/sh
# Device Remote Lock https://developer.jamf.com/jamf-pro/reference/createcomputercommandbycommand

# API login

# Jamf Pro API Credentials
jamfProAPIClient="4463-b651-e09b1df6317b"
jamfProAPISecret="_eMjE35imjoVnQElR7f5yqjX"
jamfProURL="https://url.com:8443"
passcode="000100"

# Token declarations
token=""

lock_message="This Mac has been locked by your organization dur to you account deactivation. To unlock, enter the system PIN or contact your Service Desk or your Manager."

#
##################################################
# Functions -- do not edit below here

# Get a bearer token for Jamf Pro API Authentication
getBearerToken(){
     # Encode credentials
     curl_response=$(curl --silent --location --request POST "${jamfProURL}/api/oauth/token" --header "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=${jamfProAPIClient}" --data-urlencode "grant_type=client_credentials" --data-urlencode "client_secret=${jamfProAPISecret}")
     # Extract the token value
     if [[ $(echo "${curl_response}" | grep -c 'token') -gt 0 ]]; then
          echo "Authentication token successfully generated"
          token=$(echo "${curl_response}" | plutil -extract access_token raw -)
          #echo "$curl_response"
     else
          echo "Auth Error: Response from Jamf Pro API access token request did not contain a token. Verify the ClientID and ClientSecret values."
          exit 1
     fi
}

checkVariables(){
     # Checking for Jamf Pro API variables
     if [ -z $jamfProAPIClient ]; then
          echo "Please enter your Jamf Pro Client ID: "
          read -r jamfProAPIClient
     fi
     
     if [  -z $jamfProAPISecret ]; then
          echo "Please enter your Jamf Pro Client Secret for $jamfProAPIClient: "
          read -r -s jamfProAPIPassword
     fi
     
     if [ -z $jamfProURL ]; then
          echo "Please enter your Jamf Pro URL (with no slash at the end): "
          read -r jamfProURL
     fi
     
     # Checking for additional variables
}

# Invalidate the token when done
invalidateToken(){
     responseCode=$(/usr/bin/curl -w "%{http_code}" -H "Authorization: Bearer ${token}" ${jamfProURL}/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
     if [[ ${responseCode} == 204 ]]
     then
          /bin/echo "Token successfully validated"
          token=""
     elif [[ ${responseCode} == 401 ]]
     then
          /bin/echo "Token already invalid"
     else
          /bin/echo "An unknown error occurred validating the token"
     fi
}

# Calling all functions

checkVariables
getBearerToken

# Automatically get the computer serial number

serialNumber=$(system_profiler SPHardwareDataType | grep Serial | /usr/bin/awk '{ print $4 }')

# Determine Jamf Pro device id
deviceID=$(curl -s -H "Accept: text/xml" -H "Authorization: Bearer ${token}" ${jamfProURL}/JSSResource/computers/serialnumber/"$serialNumber" | xmllint --xpath '/computer/general/id/text()' -)

# Check if device ID was retrieved successfully
if [[ -z "$deviceID" ]]; then
    echo "Failed to retrieve device ID for computer: $computerName. Exiting."
    exit 1
fi

# Display device ID for testing
echo "Device ID: $deviceID"

# send data to Jamf Pro Classic API with command to Lock Command
response=$( /usr/bin/curl \
--header "Authorization: Bearer $token" \
--header "Content-Type: text/xml" \
--request POST \
--silent \
--url "$jamfProURL/JSSResource/computercommands/command/DeviceLock/passcode/$passcode/id/$deviceID" )

echo "$response"

echo "Device lock command sent:$passcode "

invalidateToken

exit 0