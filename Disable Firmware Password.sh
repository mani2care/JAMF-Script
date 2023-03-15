#!/bin/bash

# Check if firmware password is enabled
if /usr/sbin/firmwarepasswd -check | grep -q "Yes"; then
    # Firmware password is enabled, delete it
    /usr/sbin/firmwarepasswd -delete
    echo "Firmware password has been disabled."
else
    # Firmware password is not enabled, do nothing
    echo "Firmware password is not enabled."
fi
