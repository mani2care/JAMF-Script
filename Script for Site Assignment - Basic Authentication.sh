#!/bin/bash

## API information
apiURL="https://euc-eme-002.abb.com:8443"
apiUser="jamfadmin"
apiPass="Jamf@dmin"

## Get a list of all sites and their IDs
allSiteData=$(curl -H "Accept: text/xml" -sfku "${apiUser}:${apiPass}" $apiURL/JSSResource/sites | xmllint --format - | awk -F'>|<' '/<name>|<id>/{print $3}')

echo "$allSiteData"

## Split out Site Names and Site IDs into arrays
allSiteNames=("$(echo "$allSiteData" | awk 'NR % 2 == 0')")
allSiteIDs=($(echo "$allSiteData" | awk 'NR % 2 == 1'))

## Prompt for a Site selection
chosenSite=$(/usr/bin/osascript << EOF
tell application "System Events"
activate
set siteNames to do shell script "printf '%s\n' "${allSiteNames[@]}""
set namesForDisplay to paragraphs of siteNames
set chosenSite to choose from list namesForDisplay with prompt "Choose a Site"
end tell
EOF)

## If a Site was chosen, determine the Site ID
if [ "$chosenSite" != "false" ]; then
    x=0
    while read SITE; do
        if [ "$SITE" == "$chosenSite" ]; then
            chosenSiteID=${allSiteIDs[$x]}
        fi
        let x=$((x+1))
    done < <(printf '%s
' "${allSiteNames[@]}")
else
    exit 0
fi

## Get the computer serial number
computerSerial=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')

## Update/change the Site for the computer
echo "<computer><general><site><id>$chosenSiteID</id><name>$chosenSite</name></site></general></computer>" | curl -X PUT -fku $apiUser:$apiPass -d @- "$apiURL/JSSResource/computers/serialnumber/$computerSerial/subset/general" -H "Content-Type: application/xml"