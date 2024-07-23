#!/bin/sh

# variable and function declarations

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# get the currently logged in user
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )

# global check if there is a user logged in
if [ -z "$currentUser" -o "$currentUser" = "loginwindow" ]; then
  echo "no user logged in, cannot proceed"
  exit 1
fi

# get the current user's UID
uid=$(id -u "$currentUser")

# convenience function to run a command as the current user
#   runAsUser command arguments...
runAsUser() {  
  if [ "$currentUser" != "loginwindow" ]; then
    launchctl asuser "$uid" sudo -u "$currentUser" "$@"
  else
    echo "no user logged in"
    # to make the function exit with an error when no user is logged in
    exit 1
  fi
}

#Turns off Recent Apps in Dock
runAsUser defaults write com.apple.dock show-recents -bool FALSE
sleep 2

# Set path for dockutil
dockutil="/usr/local/bin/dockutil"

# Removal of Apple Default Dock Applications
${dockutil} --remove all -allhomes --no-restart
sleep 2
${dockutil} --remove 'Launchpad' --allhomes --no-restart
${dockutil} --remove 'Safari' --allhomes --no-restart
${dockutil} --remove 'Messages' --allhomes --no-restart
${dockutil} --remove 'Mail' --allhomes --no-restart
${dockutil} --remove 'Maps' --allhomes --no-restart
${dockutil} --remove 'Photos' --allhomes --no-restart
${dockutil} --remove 'FaceTime' --allhomes --no-restart
${dockutil} --remove 'Calendar' --allhomes --no-restart
${dockutil} --remove 'Contacts' --allhomes --no-restart
${dockutil} --remove 'Reminders' --allhomes --no-restart
${dockutil} --remove 'Notes' --allhomes --no-restart
${dockutil} --remove 'Freeform' --allhomes --no-restart
${dockutil} --remove 'TV' --allhomes --no-restart
${dockutil} --remove 'Music' --allhomes --no-restart
${dockutil} --remove 'Podcasts' --allhomes --no-restart
${dockutil} --remove 'News' --allhomes --no-restart
${dockutil} --remove 'App Store' --allhomes --no-restart
${dockutil} --remove 'System Settings' --allhomes --no-restart

# Adds UJET suite of apps to dock
${dockutil} --add /Applications/Google\ Chrome.app --allhomes --after 'Finder' --no-restart
${dockutil} --add /Applications/Slack.app --allhomes --after 'Google Chrome' --no-restart
${dockutil} --add /Applications/zoom.us.app --allhomes --after 'Slack' --no-restart
${dockutil} --add /Applications/1Password\ 7.app --allhomes --after 'zoom.us' --no-restart
${dockutil} --add /Applications/'Kandji Self Service.app' --label 'Self Service' --allhomes --after '1Password 7' --no-restart
${dockutil} --add /Applications/System\ Settings.app --allhomes --after 'Self Service' --no-restart

# Adds Downloads folder to the dock in fan view
${dockutil} --add '~/Downloads' --allhomes --view fan

killall cfprefsd
killall Dock

# Exit without error code
exit 0
