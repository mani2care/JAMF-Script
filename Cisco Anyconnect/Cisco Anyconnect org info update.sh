#!/bin/bash
DATA='{
    "organizationId" : "XXXXXXX",
    "fingerprint" : "XXXXXX",
    "userId" : "XXXXXXX"
}
'
echo "$DATA" > "/Library/Application Support/JAMF/Waiting Room/OrgInfo.json"
