#!/bin/bash

# Check if remote login is enabled
login_enabled=$(sudo systemsetup -getremotelogin | awk '{print $3}')

if [ "$login_enabled" == "On" ]; then
    echo "Remote login was enabled hence Disabling it..."
    echo "yes" | sudo systemsetup -setremotelogin off
    systemsetup -f -setremotelogin off
    sudo launchctl unload -w /System/Library/LaunchDaemons/ssh.plist
	sudo launchctl stop com.openssh.sshd
    echo "Remote Login has been disabled."
    sudo launchctl list | grep ssh
else
    echo "Remote Login is already disabled."
fi

# Check if remote management is enabled
#management_process=$(ps -axlww | grep ARD)

#if [ -n "$management_process" ]; then
    #echo "Remote management is enabled. Disabling it..."
    #sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -configure -access -off
    #echo "Remote management has been disabled."
#else
    #echo "Remote management is already disabled."
#fi

# Check if remote management is enabled
agent_process=$(pgrep -x ARDAgent)

if [ -n "$agent_process" ]; then
    echo "Remote Management was enabled hence Disabling it..."
    #sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -configure -access -off >> /dev/null 2>&1
     sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -stop >> /dev/null 2>&1
    echo "Remote Management has been disabled."
else
    echo "Remote Management is already disabled."
fi

sleep 2
# Check if remote login is disabled
login_enabled1=$(sudo systemsetup -getremotelogin | awk '{print $3}')

# Check if remote management is disabled
agent_process1=$(pgrep -x ARDAgent)

if [ "$login_enabled1" == "Off" ] && [ -z "$agent_process1" ]; then
    echo "Remote Login and Remote Management are disabled."
else
    echo "Failed to disable status of Remote Login and/or Remote Management"
fi

exit
