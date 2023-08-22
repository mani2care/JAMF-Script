#!/bin/bash

#Enter the desired RSR version below as a parameter
desired_rsr="$4" #define the miner patch or rapide patch version

# Get the macOS product version information
product_version=$(sw_vers -productVersion)
product_version_extra=$(sw_vers -productVersionExtra)
full_product_version="$product_version$product_version_extra"

# Print full product version
echo "$full_product_version"

# Determine if Nudge needs to be opened
if [[ $full_product_version == $desired_rsr ]]
then 
	echo "Rapid Security Response installed."
	exit 0
else
	echo "Software Update Required."
	open -a /Applications/Utilities/Nudge.app
fi

exit 0		## Success
exit 1		## Failure
