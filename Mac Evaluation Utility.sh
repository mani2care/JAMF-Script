#!/bin/bash

# compatible with Mac Evaluation Utility version 4.0.1 (2)

applpth='/Applications/Mac Evaluation Utility.app'
compnam="$(/usr/sbin/scutil --get ComputerName)"
crntusr="$(/usr/bin/stat -f %Su /dev/console)"
rprtend=''
rprtpth="/private/tmp/$compnam.meu"
sprtpth="/Users/$crntusr/Library/Application Support/Mac Evaluation Utility/"
sqltpth="$sprtpth/MacEvalUtility.sqlite"


>&2 /bin/echo 'removing old files...'
/usr/bin/pkill -ai "Mac Evaluation"
/bin/sleep 1
/bin/rm -rf "$rprtpth" "$sprtpth"


>&2 /bin/echo 'executing Mac Eval Util...'
/usr/bin/open "$applpth"
/bin/sleep 3
/usr/bin/osascript \
	-e 'tell application "System Events"' \
	-e 'keystroke return' \
	-e 'delay 1' \
	-e 'keystroke "r" using command down' \
	-e 'end tell'


complete(){
/usr/bin/osascript \
	-e 'tell application "System Events"' \
	-e 'activate application "Mac Evaluation Utility"' \
	-e 'get static text of group 1 of toolbar 1 of window "Mac Evaluation Utility" of application process "Mac Evaluation Utility" of application "System Events"' \
	-e 'end tell'
}
until echo "$rprtend" | /usr/bin/grep -q 'Report Complete'
do
	rprtend="$(complete)"
	>&2 /bin/echo 'waiting for Mac Eval Util...'
	/bin/sleep 3
done
>&2 /bin/echo 'report complete.'

rprtpth="/private/tmp/$compnam.meu"

if [ -n "$(/usr/bin/sqlite3 -ascii "$sqltpth" 'select ZEND from ZSESSION;' 2> /dev/null)" ]
then
	>&2 /bin/echo "attempting to send "$rprtpth" to IT Support..."
	/usr/bin/osascript \
		-e 'tell application "System Events"' \
		-e 'keystroke "s" using {shift down, command down}' \
		-e 'delay 2' \
		-e 'keystroke "/"' \
		-e 'delay 2' \
		-e 'keystroke "private"' \
		-e 'delay 2' \
		-e 'keystroke "/"' \
		-e 'delay 2' \
		-e 'keystroke "tmp"' \
		-e 'delay 2' \
		-e 'keystroke return' \
		-e 'delay 2' \
		-e 'click button "Save" of window "Save" of application process "Mac Evaluation Utility"' \
		-e 'end tell'
fi
/usr/bin/open '/Applications/Microsoft Outlook.app'
/bin/sleep 3
/usr/bin/osascript \
	-e 'tell application "Microsoft Outlook"' \
	-e "set theFile to \"$rprtpth\" as POSIX file" \
	-e "set theMessage to make new outgoing message with properties {subject:\"Mac Evaluation Utility $compnam\"}" \
	-e 'tell theMessage' \
	-e 'make new to recipient with properties {email address:{address:"manikandan.r@wipro.abb.com"}}' \
	-e 'tell theMessage' \
	-e 'make new attachment with properties {file:theFile}' \
	-e 'send theMessage' \
	-e 'end tell' \
	-e 'end tell' \
	-e 'end tell'

/usr/bin/pkill -ail "Mac Evaluation"
>&2 /bin/echo "exiting..."