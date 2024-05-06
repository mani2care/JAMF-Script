#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# doc and example about making webhooks at  https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/connectors-using?tabs=cURL
# Adaptive Card samples and templates https://adaptivecards.io/samples/
#
# Tested and written for Jamf
# Set $4 to be your Activity Title 
# Set $5 to be your Activity Message 
# Set $6 to be your Icon image that appears in Teams with the message 
#    Save your icon in Jamf in the self service icon library.  Then right click on the icon to get the full web address.  
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set the Teams webhook URL 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

webhookURL="https://[yourserver].webhook.office.com/webhookb2/c86933dc-blade-4da0-4077-f93g1562c12a@cmnb0fb5-f7ff-48b4-a0d0-9f00ef96ecf9/IncomingWebhook/gaby3x9fd58043abad0592bedt564113/c3ee37ca-1941-4fg3-95d0-9981b3eccc89"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Customize the message here
# 
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # When running the script in Jamf, you can set $4 and $5 as inputs instead of hard code in the script
    activityTitle="${4:-""}"
    # activityTitle="Application Alert: Carbonite"

    activityInfo="${5:-""}"
    # activityInfo="Looks like Carbonite was removed"

    # Set the icon that appears in Teams: activityImage="https://yada.ics.services.jamfcloud.com/icon/hash_yada-yada-yada-bf332c3f71d49fd650e6459bd47"
    # If making an alert, this could be the icon from self service.  
    # In Jamf > Computer > Policy > YourPolicy > Self Service, scroll down to the icon, Right click on the icon and Copy Image Address
    # If running as a script in Jamf, set the image url to $6
    activityImage="${6:-""}"
    # activityImage="https://yada.ics.services.jamfcloud.com/icon/hash_2024mar75ba61356cde6fxyzqrstuv001d08eaf13512f939798c5"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Information about the logged in user and computer that can be used in the Teams message
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

jamfProURL=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
jamfProComputerURL="${jamfProURL}computers.html?id=${computerID}&o=r"
jamfBinary="/usr/local/bin/jamf"
dialogBinary="/usr/local/bin/dialog"
osVersion=$( sw_vers -productVersion )
osBuild=$( sw_vers -buildVersion )
osMajorVersion=$( echo "${osVersion}" | awk -F '.' '{print $1}' )
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
loggedInUserFullname=$( id -F "${loggedInUser}" )
loggedInUserFirstname=$( echo "$loggedInUserFullname" | sed -E 's/^.*, // ; s/([^ ]*).*/\1/' | sed 's/\(.\{25\}\).*/\1…/' | awk '{print toupper(substr($0,1,1))substr($0,2)}' )
macOSproductVersion="$( sw_vers -productVersion )"
macOSbuildVersion="$( sw_vers -buildVersion )"
serialNumber=$( system_profiler SPHardwareDataType | grep Serial |  awk '{print $NF}' )
dialogVersion=$( /usr/local/bin/dialog --version )
computerName=$(scutil --get ComputerName)
titleAndName="$activityTitle"-"$loggedInUser"
currentTime=$( date +%Y-%m-%d\ %H:%M:%S )
hookTime=$( echo "$currentTime")

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Build the JSON
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

webHookdata=$(cat <<EOF
{
    "@type": "MessageCard",
    "@context": "http://schema.org/extensions",
    "themeColor": "E4002B",
    "summary": "${titleAndName}",
    "sections": [{
        "activityTitle": "${titleAndName}",
        "activitySubtitle": "${jamfProURL}",
        "activityImage": "${activityImage}",
        "facts": [{
            "name": "Info: ",
            "value": "${activityInfo}"
        }, {
            "name": "Time",
            "value": "${hookTime}"
        }, {
            "name": "User",
            "value": "${loggedInUser}"
        }, {
            "name": "Mac Serial",
            "value": "${serialNumber}"
        }, {
            "name": "Computer Name",
            "value": "${computerName}"
        }, {
            "name": "Operating System Version",
            "value": "${osVersion}"
}],
        "markdown": true,
        "potentialAction": [{
        "@type": "OpenUri",
        "name": "View in Jamf Pro",
        "targets": [{
        "os": "default",
            "uri": "${jamfProComputerURL}"
            }]
        }]
    }]
}
EOF
)

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Send the webHookdata to Teams via the URL
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# curl -H 'Content-Type: application/json' -d '{"text": "Hello World"}' $webhookURL
curl --request POST \
    --url "${webhookURL}" \
    --header 'Content-Type: application/json' \
    --data "${webHookdata}"
