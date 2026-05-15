#!/bin/zsh

#get user
loggedInUser=$( /usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
#set preference
su $loggedInUser -c "/usr/bin/defaults write ~/Library/Preferences/com.jamf.selfserviceplus.plist com.jamfsoftware.selfservice.onboardingcomplete -bool TRUE"
