#!/bin/bash

# Set log file location
LOGFILE=/var/log/firmwarepasswd.log

# Check firmware password status
fw_status=$( /usr/sbin/firmwarepasswd -check 2>&1 )
echo "$(date '+%Y-%m-%d %H:%M:%S') Firmware password status: $fw_status" >> "$LOGFILE"

if [[ $fw_status == *"Yes"* ]]; then
    # Firmware password is enabled, delete it
    if ! /usr/sbin/firmwarepasswd -delete >> "$LOGFILE" 2>&1; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') Error: Failed to delete firmware password." >&2
        exit 1
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S') Firmware password has been successfully deleted." >> "$LOGFILE"
else
    # Firmware password is not enabled
    echo "$(date '+%Y-%m-%d %H:%M:%S') Firmware password is not enabled." >> "$LOGFILE"
fi

# Log script output
echo "$(date '+%Y-%m-%d %H:%M:%S'): Firmware password deletion script run" >> "$LOGFILE"
