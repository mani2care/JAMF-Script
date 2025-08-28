#!/bin/bash

#if the AAD is registred and device is compliance then sync with jamf and Azure to make the compliance

CONSOLE_USER=$(stat -f "%Su" /dev/console)
if [[ "$CONSOLE_USER" == "root" || -z "$CONSOLE_USER" ]]; then
  echo "No user logged in to GUI. Exiting."
  exit 1
fi

# Get the current logged-in user and UID
CURRENT_USER=$(/usr/bin/stat -f "%Su" /dev/console)
USER_UID=$(/usr/bin/id -u "$CURRENT_USER")

# Clean AAD info as user
launchctl asuser "$USER_UID" sudo -u "$CURRENT_USER" /usr/local/jamf/bin/jamfaad clean -verbose

# Run gatherAADInfo with full path as user in GUI context
launchctl asuser "$USER_UID" sudo -u "$CURRENT_USER" \
"/Library/Application Support/JAMF/Jamf.app/Contents/MacOS/Jamf Conditional Access.app/Contents/MacOS/Jamf Conditional Access" gatherAADInfo

# Run jamf recon (optional)
jamf recon -verbose
