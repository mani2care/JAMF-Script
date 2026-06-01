#!/bin/bash

# 1- pull the device list from dedicated group 
# 2- send the each device to remove mdm commend 
# 3- change the status to unmanaged 

# Jamf Parameters

CLIENT_ID="$4"
CLIENT_SECRET="$5"
GROUP_ID="$6"
JAMF_URL="$7"

# Output File
OUTPUT_FILE="/Users/Shared/JAMF_Automation/Pull the Group Of devices/jamf_group_devices-managed-to-unmanaged.tsv"
OUTPUT_FILE2="/Users/Shared/JAMF_Automation/Pull the Group Of devices/jamf_group_devices-send-mdm-remove-commend-log.tsv"

# Remove old file if exists
rm -f "$OUTPUT_FILE"
rm -f "$OUTPUT_FILE2"

GetJamfProAPIToken() {

# This function uses the API client ID and client ID secret to get a new bearer token for API authentication.

if [[ $(/usr/bin/sw_vers -productVersion | awk -F . '{print $1}') -lt 12 ]]; then
   ACCESS_TOKEN=$(/usr/bin/curl -s -X POST "$JAMF_URL/api/v1/oauth/token" --header 'Content-Type: application/x-www-form-urlencoded' --data-urlencode client_id="$CLIENT_ID" --data-urlencode 'grant_type=client_credentials' --data-urlencode client_secret="$CLIENT_SECRET" | python -c 'import sys, json; print json.load(sys.stdin)["access_token"]')
else
   ACCESS_TOKEN=$(/usr/bin/curl -s -X POST "$JAMF_URL/api/v1/oauth/token" --header 'Content-Type: application/x-www-form-urlencoded' --data-urlencode client_id="$CLIENT_ID" --data-urlencode 'grant_type=client_credentials' --data-urlencode client_secret="$CLIENT_SECRET" | plutil -extract access_token raw -)
fi

}
GetJamfProAPIToken


# Validate token
if [[ -z "$ACCESS_TOKEN" ]]; then
    echo "Failed to get access token"
    exit 1
fi

#echo -e "ComputerID\tComputerName\tSerialNumber" > "$OUTPUT_FILE"

# Download Group Members
GROUP_XML=$(curl -s \
--header "Authorization: Bearer ${ACCESS_TOKEN}" \
--header "Accept: application/xml" \
"${JAMF_URL}/JSSResource/computergroups/id/${GROUP_ID}")

# Extract Computer IDs
COMPUTER_IDS=$(echo "$GROUP_XML" | xmllint --xpath '//computer/id/text()' - 2>/dev/null | tr ' ' '\n')

# Loop Through Each Device
for ID in $COMPUTER_IDS; do

    DEVICE_XML=$(curl -s \
    --header "Authorization: Bearer ${ACCESS_TOKEN}" \
    --header "Accept: application/xml" \
    "${JAMF_URL}/JSSResource/computers/id/${ID}")

    REMOVE_RESPONSE=$(curl -s --request POST \
    --url "${JAMF_URL}/api/v1/computer-inventory/${ID}/remove-mdm-profile" \
    --header "accept: application/json" \
    --header "Authorization: Bearer ${ACCESS_TOKEN}")

    COMPUTER_NAME=$(echo "$DEVICE_XML" | xmllint --xpath 'string(//general/name)' - 2>/dev/null)
    SERIAL_NUMBER=$(echo "$DEVICE_XML" | xmllint --xpath 'string(//general/serial_number)' - 2>/dev/null)

    echo -e "${ID}\t${COMPUTER_NAME}\t${SERIAL_NUMBER}" >> "$OUTPUT_FILE2"
    #echo -e "${REMOVE_RESPONSE}" >> "$OUTPUT_FILE2"
    echo -e "${ID}" >> "$OUTPUT_FILE"
    sleep 0.10
done

DEVICE_COUNT=$(tail -n +1 "$OUTPUT_FILE" | wc -l | xargs)

echo "TSV File Created: $OUTPUT_FILE"
echo "Total Devices Pulled From Jamf: $DEVICE_COUNT"

exit 0