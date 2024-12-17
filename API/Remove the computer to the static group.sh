#!/bin/bash

# Fetch parameters from Jamf policy
#API Role just needs = Update Static Computer Groups and Read Computers.

CLIENT_ID="$4"
CLIENT_SECRET="$5"
STATIC_GROUP_ID="$6"
JAMF_URL="$7"

# Debugging: Display static group ID and Jamf URL without sensitive info
echo "STATIC_GROUP_ID: $STATIC_GROUP_ID"
echo "JAMF_URL: $JAMF_URL"

# Get the serial number
SERIAL_NUMBER=$(ioreg -l | awk '/IOPlatformSerialNumber/ { print $4;}' | sed 's/"//g')
echo "Serial Number: $SERIAL_NUMBER"

# Authenticate and get an access token
AUTH_RESPONSE=$(curl --location --request POST "$JAMF_URL/api/oauth/token" \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode "client_id=$CLIENT_ID" \
--data-urlencode "grant_type=client_credentials" \
--data-urlencode "client_secret=$CLIENT_SECRET" --silent)

# Debugging: Display auth response status (remove sensitive details)
if [[ $AUTH_RESPONSE == *"access_token"* ]]; then
echo "Auth Response: Successfully retrieved access token"
else
echo "Auth Response: Failed to retrieve access token"
echo "Response: $AUTH_RESPONSE"
exit 1
fi

# Extract access token from the response
ACCESS_TOKEN=$(echo $AUTH_RESPONSE | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

# Get the Jamf Pro device ID using the access token
DEVICE_ID=$(curl -s -H "Accept: text/xml" -H "Authorization: Bearer ${ACCESS_TOKEN}" "${JAMF_URL}/JSSResource/computers/serialnumber/${SERIAL_NUMBER}" | xmllint --xpath '/computer/general/id/text()' -)
echo "Device ID: $DEVICE_ID"

# Check if DEVICE_ID was successfully retrieved
if [ -z "$DEVICE_ID" ]; then
echo "Failed to obtain Device ID"
exit 1
fi

# Add the computer to the static group
apiURL="JSSResource/computergroups/id/${STATIC_GROUP_ID}"
xmlHeader="<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
apiData="<computer_group><id>${STATIC_GROUP_ID}</id><computer_additions><computer><id>${DEVICE_ID}</id></computer></computer_additions></computer_group>"

ADD_COMPUTER_RESPONSE=$(curl -s \
--header "Authorization: Bearer ${ACCESS_TOKEN}" --header "Content-Type: text/xml" \
--url "${JAMF_URL}/${apiURL}" \
--data "${xmlHeader}${apiData}" \
--request PUT)

# Validate if the computer was added successfully
if echo "$ADD_COMPUTER_RESPONSE" | grep -q "<id>${STATIC_GROUP_ID}</id>"; then
echo "Successfully added computer to static group"
else
echo "Failed to add computer to static group"
echo "Response: $ADD_COMPUTER_RESPONSE"
exit 1
fi

exit 0
