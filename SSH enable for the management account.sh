#!/bin/bash
#Note that we remove all current users so only we have SSH access and then add our management account. Update ManageAccount as needed.
ManageAccount="CHANGE_ME"

#Lets Turn off SSH
launchctl unload /System/Library/LaunchDaemons/ssh.plist

# remove the existing SSH access group (revert to all user access)
dseditgroup -o delete -t group com.apple.access_ssh

# Re-Create and add the users
dseditgroup -o create -q com.apple.access_ssh
dseditgroup -o edit -a $ManageAccount -t user com.apple.access_ssh

# Turn SSH back on
launchctl load /System/Library/LaunchDaemons/ssh.plist
