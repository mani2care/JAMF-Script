#!/bin/bash

###
#
#            Name:  Reset Safari.sh
#     Description:  Resets all Safari user data to defaults for the currently
#                   logged-in user.

########## variable-ing ##########



loggedInUser=$(/usr/bin/stat -f%Su "/dev/console")
loggedInUserHome=$(/usr/bin/dscl . -read "/Users/$loggedInUser" NFSHomeDirectory | /usr/bin/awk '{print $NF}')
userLibrary="$loggedInUserHome/Library"
uuid=$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk '/Hardware UUID/ {print $NF}')
preferencesToReset=(
  "$userLibrary/Caches/Metadata/Safari"
  "$userLibrary/Caches/com.apple.Safari"
  "$userLibrary/Caches/com.apple.WebKit.PluginProcess"
  "$userLibrary/Cookies/Cookies.binarycookies"
  "$userLibrary/Preferences/ByHost/com.apple.Safari.$uuid.plist"
  "$userLibrary/Preferences/com.apple.Safari.LSSharedFileList.plist"
  "$userLibrary/Preferences/com.apple.Safari.RSS.plist"
  "$userLibrary/Preferences/com.apple.Safari.plist"
  "$userLibrary/Preferences/com.apple.Safari.plistls"
  "$userLibrary/Preferences/com.apple.WebFoundation.plist"
  "$userLibrary/Preferences/com.apple.WebKit.PluginHost.plist"
  "$userLibrary/Preferences/com.apple.WebKit.PluginProcess.plist"
  "$userLibrary/PubSub/Database"
  "$userLibrary/Safari"
  "$userLibrary/Saved Application State/com.apple.Safari.savedState"
)



########## main process ##########



# Delete Safari preference files.
echo "Deleting Safari preference files to reset to system default..."
for safariPref in "${preferencesToReset[@]}"; do
  if [ -e "$safariPref" ]; then
    /bin/rm -rv "$safariPref"
  fi
done



exit 0
