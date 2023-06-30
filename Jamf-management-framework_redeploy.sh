#!/bin/bash

#Required below API Details
JAMFURL=""
JAMFUSER=""
JAMFPASS=""
#Define group static or dynamic group any one is fine.
GROUPID="126" 


BASIC=$(echo -n "$JAMFUSER":"$JAMFPASS" | base64)

#Request a token
authToken=$(curl -s \
    --request POST \
    --url "${JAMFURL}/api/v1/auth/token" \
    --header 'Accept: application/json' \
    --header "Authorization: Basic $BASIC" \ 
)

#Exract token
apitoken=$( /usr/bin/plutil -extract token raw - <<< "$authToken" )

#Find computer IDs
content=$(curl -s \
    --request GET \
    --url "$JAMFURL/JSSResource/computergroups/id/$GROUPID" \
    --header "Authorization: Bearer $apitoken" \
    --header "accept text/xml" \
    | xmllint --xpath "//computer/id/text()" -
)

#Redeploy framework
for id in $content; do
curl -s \
    --request POST \
    --url "$JAMFURL/api/v1/jamf-management-framework/redeploy/$id"  \
    --header "Authorization: Bearer $apitoken" \
    --header "accept: application/json"
done
