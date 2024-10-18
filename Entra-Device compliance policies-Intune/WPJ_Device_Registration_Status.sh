#!/bin/bash

# Get the currently logged-in user
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )

# Global check if there is a user logged in
if [ -z "$currentUser" -o "$currentUser" = "loginwindow" ]; then
  exit 1
fi

# Get the current user's UID
uid=$(id -u "$currentUser")

# Convenience function to run a command as the current user
runAsUser() {
  if [ "$currentUser" != "loginwindow" ]; then
    launchctl asuser "$uid" sudo -u "$currentUser" "$@"
  fi
}

# Retrieve the AAD ID of the current user
AAD_ID=$(runAsUser security find-certificate -a -Z | grep -B 9 "MS-ORGANIZATION-ACCESS" | awk '/\"alis\"<blob>=\"/ {print $NF}' | sed 's/^"alis"<blob>="//;s/"$//')

# Check if AAD_ID was successfully retrieved
if [ -z "$AAD_ID" ]; then
  echo "<result>NO_WPJ_Cert</result>"
else
  echo "<result>$AAD_ID</result>"
fi
