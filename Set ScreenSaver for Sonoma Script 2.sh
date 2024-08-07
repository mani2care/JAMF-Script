#!/bin/bash

### Thanks to HowieIsaacks to provide this script on Mac Admins Slack channel. (http://www.linkedin.com/in/howieisaacks)
### Replace the folderpath in line 27 with the location where custom screensaver image is placed.

## Get current user
current_user=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
current_user_id=$(/usr/bin/id -u "$current_user")
echo "Current user is "$current_user""
echo "Current user ID is "$current_user_id""

sleep 10
## Set key values for screen saver
echo "Setting key values for screen saver"
sudo -u "$current_user" /usr/bin/defaults -currentHost write com.apple.screensaver CleanExit -string "YES"
sudo -u "$current_user" /usr/bin/defaults -currentHost write com.apple.screensaver PrefsVersion -int 100
sudo -u "$current_user" /usr/bin/defaults -currentHost write com.apple.screensaver showClock -string "NO"
## set value to start the screensaver in seconds (now set it to start at 5 minute [start at 299 seconds])
sudo -u "$current_user" /usr/bin/defaults -currentHost write com.apple.screensaver idleTime -int 299
## Configure screen saver framework
echo "configuring screen saver framework"
sudo -u "$current_user" /usr/bin/defaults -currentHost write com.apple.screensaver moduleDict -dict moduleName -string "iLifeSlideshows" path -string "/System/Library/ExtensionKit/Extensions/iLifeSlideshows.appex" type -int 0
## Additional configuration settings for screen saver framework
echo "configuring screen saver settings"
sudo -u "$current_user" defaults -currentHost write com.apple.screensaver tokenRemovalAction -int 0
echo "setting asset path"
sudo -u "$current_user" defaults -currentHost write com.apple.ScreenSaverPhotoChooser SelectedFolderPath -string "/Library/Screen Savers/Customname"
echo "setting shuffle settings"
sudo -u "$current_user" defaults -currentHost write com.apple.ScreenSaverPhotoChooser SelectedSource -int 3
sudo -u "$current_user" defaults -currentHost write com.apple.ScreenSaverPhotoChooser ShufflesPhotos -bool "true"
sudo -u "$current_user" defaults -currentHost write com.apple.ScreenSaver.iLifeSlideShows styleKey -string "Classic"
## Reset prefsd
echo "relaunching prefsd..."
/usr/bin/killall -hup cfprefsd