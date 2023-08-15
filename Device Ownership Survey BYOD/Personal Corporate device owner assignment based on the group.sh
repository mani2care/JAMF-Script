#!/bin/bash

#this script is for updating the device owner name in to extension attribute based on the smart computer group

# Required API Details
JAMFURL="https://cloud:8443"
JAMFUSER="jamf"
JAMFPASS="Jamf"

# Define group static or dynamic group, any one is fine.
GROUPID="126" #your smart computer target group 
selectedOption="Corporate" # Personal/Corporate extension attribut must be created as on the same give below $eaName
eaName="Ownership" #extension attribute name.

#id=$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk '/Hardware UUID:/ { print $3 }')

BASIC=$(echo -n "$JAMFUSER":"$JAMFPASS" | base64)

# Request a token
authToken=$(curl -s \
    --request POST \
    --url "${JAMFURL}/uapi/auth/tokens" \
    --header 'Accept: application/json' \
    --header "Authorization: Basic $BASIC"
)

# Extract token
apitoken=$( /usr/bin/plutil -extract token raw - <<< "$authToken" )

# Find computer IDs
content=$(curl -s \
    --request GET \
    --url "$JAMFURL/JSSResource/computergroups/id/$GROUPID" \
    --header "Authorization: Bearer $apitoken" \
    --header "accept: text/xml" \
    | xmllint --xpath "//computer/id/text()" -
)

# Force the Ownership
for id in $content; do
    curl -s -X PUT -H "Content-Type: application/xml" -H "Authorization: Bearer $apitoken" -d "<computer><extension_attributes><extension_attribute><name>$eaName</name><value>$selectedOption</value></extension_attribute></extension_attributes></computer>" "$JAMFURL/JSSResource/computers/id/$id"
echo""
done
