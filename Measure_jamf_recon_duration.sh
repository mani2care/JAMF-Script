#!/bin/bash

# Record start time
start_time=$(date +%s)

# Run jamf recon with sudo
sudo jamf recon > /dev/null 2>&1

# Calculate duration
end_time=$(date +%s)
duration=$((end_time - start_time))

# Print duration in minutes and seconds
minutes=$((duration / 60))
seconds=$((duration % 60))
echo "Duration: $minutes minutes $seconds seconds"
