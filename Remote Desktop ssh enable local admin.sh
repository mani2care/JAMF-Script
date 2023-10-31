#!/bin/bash
# Built by Grant Brinkman 2022-10-10
# Compatible with Mac OS 12.0+

# The user you want to enable ssh for
ssh_user="remoteuser"

# Check if ssh is enabled
remote_login_check=$(sudo systemsetup -getremotelogin)

if [ "$remote_login_check" != "Remote Login: On" ] ; then
    # turn ssh on
    systemsetup -setremotelogin on
fi

# append user to ssh group
# Script to enable specified users of SSH on OS X systems

# Remove the existing SSH access group (revert to all user access)
dseditgroup -o delete -t group com.apple.access_ssh

# Create the access group again anew
dseditgroup -o create -q com.apple.access_ssh

# Add the standard remote admin management account
dseditgroup -o edit -a $ssh_user -t user com.apple.access_ssh

# restart ssh
launchctl unload /System/Library/LaunchDaemons/ssh.plist
sleep 5
launchctl load -w /System/Library/LaunchDaemons/ssh.plist

# Check if ssh is already enabled for that user
check_ssh_group=$(dscl . -read /Groups/com.apple.access_ssh | grep GroupMembership | grep -o $ssh_user)

# If the user was not added to the SSH group successfully, exit with error.
if [[ ! $check_ssh_group ]]; then
    echo "$ssh_user not found in SSH access group"
    exit 1
else
    echo "$ssh_user is in SSH access group"
    exit 0
fi
