#!/bin/zsh

#get user
loggedInUser=$( /usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
#set preference
su $loggedInUser -c "/usr/bin/defaults write ~/Library/Preferences/com.jamfsoftware.selfservice.mac.plist com.jamfsoftware.selfservice.onboardingcomplete -bool TRUE"
