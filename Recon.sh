#!/bin/bash

# The purpose of this script is to allow Jamf to run recon after policies
# without requiring it wait for it to finish.

# Check if recon is currently running
/bin/ps ax | /usr/bin/grep -i "jamf recon" | /usr/bin/grep -v grep > /dev/null 2>&1

if [[ $? -eq 1 ]]; then
    /usr/bin/nohup /usr/local/bin/jamf recon -verbose > /tmp/recon.out 2>&1 &
else
    echo "Jamf recon already running, exiting..."
fi

exit 0
