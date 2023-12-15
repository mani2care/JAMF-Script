#!/bin/sh
# Get the JSS URL from the Mac's jamf plist file
if [ -e "/Library/Preferences/com.jamfsoftware.jamf.plist" ]; then
    jssURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
else
    echo "No JSS file...(/Library/Preferences/com.jamfsoftware.jamf.plist) exiting"
    exit 1
fi

jssUser="$4"
jssPass="$5"
jssHost=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed 's|/$||')

serial=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')

username=$(/usr/bin/curl -H "Accept: text/xml" -sfku "${jssUser}:${jssPass}" "${jssHost}/JSSResource/computers/serialnumber/${serial}/subset/location" | xmllint --format - 2>/dev/null | awk -F'>|<' '/<username>/{print $3}')

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
            echo "Read the Netbiosname ""
            defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server.plist NetBIOSName
        else

            echo "Hostname already same as $oldcomputername not required to change exiting."
             
         fi
     }

        validation_check
        exit

 fi
 
