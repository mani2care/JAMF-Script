#!/bin/sh

# This script updates the username on a macOS system.
# It retrieves the new username from Active Directory (AD) via the `profiles` command.
# If the new username is not found, the script exits with an error.
# If the username is found, it renames the existing user to the new username.
# created by : mani2care


#newusername="manikandan" your short ID 

newusername=$(profiles -P -o stdout | grep -i -A 20 "User Info" | grep "username" | awk -F'=' '{gsub(/^ *| *$/,"",$2); print $2}' | tr -d ';' 2>/dev/null)

# Check if newusername is empty
if [ -z "$newusername" ]; then
  echo "Error: User short ID is empty. Exiting script."
  exit 1
fi

echo "The User short ID is from AD $newusername"

ShortName=`/usr/bin/who | awk '/console/{ print $1 }'`
echo "Old Name is $ShortName"


# Check if the name is already changed
CurrentName=$(dscl . -read /Users/$ShortName RecordName 2>/dev/null | awk '{print $2}')

if [ "$CurrentName" = "$newusername" ]; then
  echo "The username is already set to $newusername. Exiting script."
  exit 0
fi


# Change the username
sudo dscl . -change /Users/$ShortName RecordName "$ShortName" "$newusername" 2>/dev/null


# Verify the change
ChangedName=$(dscl . -read /Users/$newusername RecordName 2>/dev/null | awk '{print $2}')

# Check if the name was successfully changed
if [ "$ChangedName" = "$newusername" ]; then
  echo "The username has been successfully changed to $ChangedName"
else
  echo "Error: Failed to change the username."
fi
