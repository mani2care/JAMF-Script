#!/bin/bash

# Record start time
start_time=$(date +%s)

# Step 1: Perform initial inventory
echo "Starting initial inventory..."
time sudo jamf recon -verbose

# Record end time
end_time=$(date +%s)

# Calculate duration
duration=$((end_time - start_time))

# Print duration
echo "Total duration: $duration seconds"
