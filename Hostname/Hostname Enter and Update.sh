#!/bin/sh
computerName=$(osascript -e 'tell application "SystemUIServer"
set myComputerName to text returned of (display dialog "Please insert device hostname (CC-L-9000000<number>) and click Submit." default answer "" with title "Asset ID" buttons {"Submit"} with icon caution)
end tell')

/usr/sbin/scutil --set ComputerName "${computerName}"
/usr/sbin/scutil --set LocalHostName "${computerName}"
/usr/sbin/scutil --set HostName "${computerName}"

dscacheutil -flushcache

echo "Computer name has been set..."
echo "<result>`scutil --get ComputerName`</result>"

exit 0
