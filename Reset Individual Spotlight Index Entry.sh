#!/bin/sh

###
#
#            Name:  Reset Individual Spotlight Index Entry.sh
#      Description: Resets Spotlight index entry for target path.

########## variable-ing ##########



# Jamf Pro script parameter: "Target Path"
# Use full path to target file in the variable.
resetPath="$4"
spotlightPlist="/.Spotlight-V100/VolumeConfiguration.plist"
macOSVersionMajor=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F . '{print $1}')
macOSVersionMinor=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F . '{print $2}')



########## function-ing ##########



# Exits with error if any required Jamf Pro arguments are undefined.
check_jamf_pro_arguments () {
  if [ -z "$resetPath" ]; then
    echo "❌ ERROR: Undefined Jamf Pro argument, unable to proceed."
    exit 74
  fi
}


# Exits with error if running an unsupported version of macOS.
check_macos_version () {
  if [ "$macOSVersionMajor" -gt 10 ] || [ "$macOSVersionMinor" -gt 14 ]; then
    /bin/echo "❌ ERROR: macOS version ($(/usr/bin/sw_vers -productVersion)) unrecognized or incompatible, unable to proceed."
    exit 1
  fi
}


# Restarts the Spotlight service.
metadata_reset () {
  /bin/launchctl stop com.apple.metadata.mds
  /bin/launchctl start com.apple.metadata.mds
}



########## main process ##########



# Verify script prerequisites.
check_jamf_pro_arguments
check_macos_version


# Verify $resetPath exists on the system.
if [ ! -e "$resetPath" ]; then
  echo "Target path $resetPath does not exist, unable to proceed. Please check Target Path parameter in Jamf Pro policy."
  exit 74
fi


# Add target path to Spotlight exclusions.
/usr/bin/defaults write "$spotlightPlist" Exclusions -array-add "$resetPath"
metadata_reset
echo "Added $resetPath to Spotlight exclusions."


# Remove target path from Spotlight exclusions.
/usr/bin/defaults delete "$spotlightPlist" Exclusions
metadata_reset
echo "Removed $resetPath from Spotlight exclusions. Target path should appear in Spotlight search results shortly."



exit 0
