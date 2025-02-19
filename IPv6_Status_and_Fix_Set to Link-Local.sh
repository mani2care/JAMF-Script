#!/bin/bash

# Start XML output for Jamf Extension Attribute
echo "<result>"

setv6="LinkLocal"  ## Change this to "Off", "Automatic", or "LinkLocal" as needed.
					# set "Manual" will couse the issue do not set its required to have a IPv6 address Prefix length (typically 64) IPv6 router address (gateway).
					# networksetup -setv6manual Wi-Fi 2001:db8::1 64 fe80::1 you need to set like this.
						
# Get a list of network services, handling spaces correctly
network_services=$(networksetup -listallnetworkservices | grep -v '*')

# Loop through each network service
while IFS= read -r service; do
    # Get the current IPv6 configuration for the service
    ipv6_status=$(networksetup -getinfo "$service" | grep "IPv6:" | awk '{print $2}')

    # If IPv6 status is empty, assume it's "LinkLocal"
    if [[ -z "$ipv6_status" ]]; then
        ipv6_status="LinkLocal"
    fi

    if [[ "$ipv6_status" == "$setv6" ]]; then
        echo "Already set to $setv6: $service"
    elif [[ "$ipv6_status" != "$setv6" ]]; then
        # Apply the new setting explicitly
        echo "Changing IPv6 to $setv6 for: $service"
        networksetup -setv6"$setv6" "$service"  # Explicit command for Automatic

        # Verify if the change was successful
        new_status=$(networksetup -getinfo "$service" | grep "IPv6:" | awk '{print $2}')
        if [[ -z "$new_status" || "$new_status" == "$setv6" ]]; then
            echo "Successfully set IPv6 to $setv6 for: $service"
            echo ""
        else
            echo "Failed to set IPv6 to $setv6 for: $service"
            echo ""
        fi
    else
        echo "Skipping: $service (Invalid or unsupported configuration)"
    fi
done <<< "$network_services"

# Close XML output
echo "</result>"

exit 0
