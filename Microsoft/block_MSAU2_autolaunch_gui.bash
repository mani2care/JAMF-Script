#!/bin/bash

# Script by Tully Jagoe
# Version 241029
# Blocks the Microsoft Automatic Update app from constantly launching itself automatically, and interrupting users
# Updates for office 365 can still be run using msupdate commands, or via VPP/MDM policies 
# https://learn.microsoft.com/en-gb/microsoft-365-apps/mac/update-office-for-mac-using-msupdate
# Also adds msupdate alias to the PATH for easy scriping and troubleshooting
# Installomator is used to install Microsoft AutoUpdate if it is missing, comment this out if you are not using installomator

# MARK: ----------------- Variables -----------------
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
binLocation="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
symlinkLocation="/usr/local/bin/msupdate"
installomator="/usr/local/Installomator/Installomator.sh"

# MARK: ----------------- Install msupdate -----------------
installMSAU2 () {
    [[ -n $(ls /Applications | grep Microsoft) ]] && echo "Microsoft apps are installed" || echo "Microsoft apps are not installed"
    [[ -f "${binLocation}" ]] && echo "msupdate binary exists" || echo "msupdate binary does not exist"

    [[ ! -f "${binLocation}" ]] && [[ -n $(ls /Applications | grep Microsoft) ]] && {
        echo -e "\nMicrosoft Apps are installed, however msupdate does not exist, installing now..."
        $installomator "microsoftautoupdate" BLOCKING_PROCESS_ACTION=ignore IGNORE_APP_STORE_APPS=no SYSTEMOWNER=1 INSTALL=force NOTIFY=silent
    }
}

# MARK: ----------------- msupdate path -----------------
addMsupdateToPath() {
    # Check if the symlink exists
    [[ ! -e "${symlinkLocation}" ]] && {
        # Ensure the target file is executable
        [[ ! -x "${binLocation}" ]] && echo "Fixing msupdate exectutable permissions..." && sudo chmod +x "${binLocation}"
        # Create the symlink
        echo "Creating symlink..."
        sudo ln -s "${binLocation}" "${symlinkLocation}" && echo "Alias created: ${symlinkLocation} -> ${binLocation}"
    }

    # Verify the symlink
    [[ -L "${symlinkLocation}" ]] && echo -e "Symlink verified" || echo "Failed to create symlink."
}

# MARK: ----------------- Demote LaunchAgent -----------------
# Configures three settings, StartInterval=0 (seconds, therefore disabled), RunAtLoad=false, and Disabled=true
demoteLaunchAgent() {
    [[ $(defaults read "/Library/LaunchAgents/com.microsoft.update.agent" StartInterval) != 0 ]] && {
        echo "Setting msupdate start interval to 0"
        sudo defaults write "/Library/LaunchAgents/com.microsoft.update.agent" StartInterval -int 0
    }

    [[ $(defaults read "/Library/LaunchAgents/com.microsoft.update.agent" RunAtLoad) = 1 ]] && {
        echo "Setting msupdate RunAtLoad to false"
        sudo defaults write "/Library/LaunchAgents/com.microsoft.update.agent" RunAtLoad -bool false
    }

    [[ $(defaults read "/Library/LaunchAgents/com.microsoft.update.agent" Disabled) = 0 ]] && {
        echo "Setting msupdate Disabled to true"
        sudo defaults write "/Library/LaunchAgents/com.microsoft.update.agent" Disabled -bool true
    }

    sudo chmod 644 "/Library/LaunchAgents/com.microsoft.update.agent.plist"
    sudo launchctl bootout system /Library/LaunchAgents/com.microsoft.update.agent.plist > /dev/null 2>&1
    # No need to reload the LaunchAgent if we are not going to use it, but the command is here if you need
    #sudo launchctl bootstrap system /Library/LaunchAgents/com.microsoft.update.agent.plist > /dev/null 2>&1
}

# MARK: ----------------- Run the jewels -----------------

echo -e "---- MSAU2 config and repair START"

# Installomator subroutine, remove this if you are not using Installomator
[[ -f "${installomator}" ]] && {
    installMSAU2
} || {
    echo "Installomator not found"
}

# Check if msupdate exists, if so add symlink, if not exit
[[ -f "${binLocation}" ]] && {
    addMsupdateToPath
} || {
    echo "msupdate binary not found, exiting..."
    exit 1
}

# Demote the LaunchAgent
demoteLaunchAgent

# Run msupdate to check for updates
sudo msupdate -i -a MSau04

echo -e "---- MSAU2 config and repair END"
