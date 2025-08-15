#!/bin/bash

# Script for: iCloud Account Type (Jamf Extension Attribute)
# Author: Manikandan R
# Purpose: Fetch all Apple ID accounts from MobileMeAccounts.plist and classify as BB or Personal

# Get the currently logged-in user
CURRENT_USER=$(stat -f "%Su" /dev/console)

# Get user's home directory
USER_HOME=$(dscl . -read "/Users/$CURRENT_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')

# Path to plist
PLIST="$USER_HOME/Library/Preferences/MobileMeAccounts.plist"

# Check if plist exists
if [[ ! -f "$PLIST" ]]; then
    echo "<result>iCloud Account not found</result>"
    exit 0
fi

# Get the number of accounts
ACCOUNT_COUNT=$(/usr/libexec/PlistBuddy -c "Print :Accounts" "$PLIST" 2>/dev/null | grep "Dict" | wc -l)

if [[ "$ACCOUNT_COUNT" -eq 0 ]]; then
    echo "<result>iCloud Account not found</result>"
    exit 0
fi

# Prepare result string
RESULTS=()

# Loop through each account index
for (( i=0; i<ACCOUNT_COUNT; i++ )); do
    ID=$(/usr/libexec/PlistBuddy -c "Print :Accounts:$i:AccountID" "$PLIST" 2>/dev/null)
    NAME=$(/usr/libexec/PlistBuddy -c "Print :Accounts:$i:DisplayName" "$PLIST" 2>/dev/null)

    # Default to empty string if not found
    ID=${ID:-""}
    NAME=${NAME:-""}

    if [[ -z "$ID" ]]; then
        continue
    fi

    if [[ "$ID" == *"bb.com"* ]]; then
        RESULTS+=("BB: $ID ($NAME)")
    else
        RESULTS+=("Personal: $ID ($NAME)")
    fi
done

# Final output
if [[ ${#RESULTS[@]} -eq 0 ]]; then
    echo "<result>iCloud Account not found</result>"
else
    echo "<result>${RESULTS[*]}</result>"
fi
