#!/bin/zsh --no-rcs
#https://philipross.github.io/posts/VPP-via-Setup-Manager/
# This script is designed to allow for VPP apps to install.
# This will be done by calling the url scheme to execute the install of the app, using the `open -j` argument to hide the SSP app GUI

#Variables that users can set
URL_SCHEME=$4
ID=$5
APP_PATH=$6
TIMEOUT_THRESHOLD=$7
SLEEP_VALUE=$8
SELF_SERVICE_NAME=$9

#Parameter	  Label	              Value
#Parameter 4	URL_SCHEME	        jamfselfservice://
#Parameter 5	ID	                1
#Parameter 6	APP_PATH	          /Applications/Slack.app
#Parameter 7	TIMEOUT_THRESHOLD	  300
#Parameter 8	SLEEP_VALUE         5
#Parameter 9	SELF_SERVICE_NAME	  Self Service+

# Fixed variables
ELAPSED_TIME=0
URL=${URL_SCHEME}content?entity=app\&id=${ID}\&action=execute

# 1. Check for presence of the app.
# If it exists, exit the script with no action taken. Report success, as the app is present.
# If it doesn't exist, then call the Self Service URL to install silently

function quit_self_service(){
/bin/sleep 2
/usr/bin/osascript -e "tell application \"$1\" to quit"
}

if [[ -d "$APP_PATH" ]]; then
    echo "$APP_PATH exists."
    echo "Not calling to install. Exiting with success"
    exit 0
else
    echo "$APP_PATH does not exist."
    echo "Calling to install..."
    open -j "$URL"
fi

# Use an until loop to act as a watchpath
until [[ -d "$APP_PATH" ]];do
    if [[ ELAPSED_TIME -ge TIMEOUT_THRESHOLD ]]
        then
            echo "Timeout threshold reached."
            echo "Marking installation as failed."
            quit_self_service $SELF_SERVICE_NAME
            exit 1
        fi

    echo "$APP_PATH does not yet exist. Looping..."
    echo "Time elapsed: $ELAPSED_TIME"

    sleep $SLEEP_VALUE
    ((ELAPSED_TIME+=SLEEP_VALUE))
done

echo "$APP_PATH exists. Completing..."
quit_self_service $SELF_SERVICE_NAME

exit 0
