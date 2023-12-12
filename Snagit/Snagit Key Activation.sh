#!/bin/sh

regkey="Your key gos here"
rm -f /Users/Shared/TechSmith/Snagit/LicenseKey

# Define folder and file paths
folder_path=/Users/Shared/TechSmith/Snagit

# Check if the folder exists
if [ -d "$folder_path" ]; then
    echo "Folder exists."
else
    # If the folder does not exist, create it
    mkdir -p "$folder_path"
	echo "Folder created."
fi
  

if [ -n "$regkey" ]; then
  [[ ! -d "/Users/Shared/TechSmith/Snagit" ]] && /bin/mkdir -p "/Users/Shared/TechSmith/Snagit"
  /bin/echo "$regkey" > "/Users/Shared/TechSmith/Snagit/LicenseKey"
  /bin/chmod -R 777 "/Users/Shared/Snagit"
  /bin/chmod a+x "/Users/Shared/TechSmith/Snagit/LicenseKey"
  #Hide the licence key
	chflags hidden /Users/Shared/TechSmith/Snagit/LicenseKey 
fi
