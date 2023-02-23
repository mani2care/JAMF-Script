#!/bin/bash

# Check if the security command is available
if ! command -v security &> /dev/null; then
    echo "The 'security' command is not available. Please make sure the script is being run on macOS."
    exit 1
fi

# Check if the macOS version is supported
macOS_version=$(sw_vers -productVersion)
if [[ $macOS_version != "12."* && $macOS_version != "13.2"* ]]; then
    echo "This script can only be run on macOS Monterey (12.x) or Ventura (13.2)"
    exit 1
fi

# Check if the settings are already allowed before attempting to modify them
if /usr/bin/security authorizationdb read system.preferences | grep -q "allow"; then
    echo "system.preferences already allowed"
else
    /usr/bin/security authorizationdb write system.preferences allow || { echo "Failed to allow system.preferences"; exit 1; }
    echo "system.preferences allowed"
fi

if /usr/bin/security authorizationdb read system.preferences.datetime | grep -q "allow"; then
    echo "system.preferences.datetime already allowed"
else
    /usr/bin/security authorizationdb write system.preferences.datetime allow || { echo "Failed to allow system.preferences.datetime"; exit 1; }
    echo "system.preferences.datetime allowed"
fi

if /usr/bin/security authorizationdb read system.preferences.dateandtime.changetimezone | grep -q "allow"; then
    echo "system.preferences.dateandtime.changetimezone already allowed"
else
    /usr/bin/security authorizationdb write system.preferences.dateandtime.changetimezone allow || { echo "Failed to allow system.preferences.dateandtime.changetimezone"; exit 1; }
    echo "system.preferences.dateandtime.changetimezone allowed"
fi

if /usr/bin/security authorizationdb read system.preferences.datetime | grep -q "authenticate-session-owner-or-admin"; then
    echo "system.preferences.datetime authenticate-session-owner-or-admin already allowed"
else
    /usr/bin/security authorizationdb write system.preferences.datetime authenticate-session-owner-or-admin || { echo "Failed to allow system.preferences.datetime authenticate-session-owner-or-admin"; exit 1; }
    echo "system.preferences.datetime authenticate-session-owner-or-admin allowed"
fi

# Allow non-admin users to set the date and time
if [[ $(/usr/sbin/dseditgroup -o checkmember -m "$USER" admin) != "yes" ]]; then
    sudo /usr/sbin/dseditgroup -o edit -a "$USER" -t user admin || { echo "Failed to add $USER to the admin group"; exit 1; }
    echo "$USER added to the admin group to allow changing the date and time."
fi

echo "Date and time settings updated successfully."

exit 0;
