#!/bin/sh
# Get the JSS URL from the Mac's jamf plist file
serial=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')

#username=$(defaults read "/Library/Managed Preferences/com.abb.deviceinfo.plist" username)
username=$( profiles -P -o stdout | grep -i -A 20 "User Info" | grep "username" | awk -F'=' '{gsub(/^ *| *$/,"",$2); print $2}' | tr -d ';')

if [ "$username" == "" ]; then
    echo "From jamf Username field is blank exiting."
    exit 1
    else
        place="$username"
        firstCharacter=${place:0:2}
        ## Laptop or Desktop
        TYPE=$(system_profiler SPHardwareDataType | grep -i "MacBook" | wc -l)
            [[ $TYPE -gt 0 ]] && T="L" || T="D"

        newcomputerName=$firstCharacter"-"$T"-"$serial

        oldcomputername=`scutil --get ComputerName`
        oldHostName=`scutil --get HostName`
        oldLocalHostName=`scutil --get LocalHostName`
echo "Attempting to change Hostname"

    validation_check () {
        if [[ "$newcomputerName" != "$oldcomputername" || "$newcomputerName" != "$oldHostName" || "$newcomputerName" != "$oldLocalHostName" ]]; then
           echo "Old computer name: $oldcomputername"
           newcomputerName=$(echo $newcomputerName | tr '[:lower:]' '[:upper:]')
           echo "Assigning New computer name: $newcomputerName"

            /usr/sbin/scutil --set HostName "$newcomputerName"
            /usr/sbin/scutil --set LocalHostName "$newcomputerName"
            /usr/sbin/scutil --set ComputerName "$newcomputerName"
            #flush DNS cache
            dscacheutil -flushcache
            killall -HUP mDNSResponder
			defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server.plist NetBIOSName "$newcomputerName"
            echo "Read the Netbiosname "
            defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server.plist NetBIOSName
            /usr/local/bin/jamf setComputerName -name $newcomputerName
        else

            echo "Hostname already same as $oldcomputername not required to change exiting."
             
         fi
     }

        validation_check
        exit

 fi