#!/bin/bash

LanSchoolStatus=$(sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db 'select * from access' |grep "kTCCServiceScreenCapture" | awk '{split($0,a,"|"); print a[2]}' |grep lanschool)

# Check to see if lanschool exists in the TCC database
if [[ "$LanSchoolStatus" == "" ]]
    then
        result="Not Prompted"
# If it exists in the database, check it's status
elif [[ "$LanSchoolStatus" == "com.lanschool.student" ]]
    then
        # Check the approval status
        lanschoolApproval=$(sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db 'select * from access' |grep "kTCCServiceScreenCapture" |grep lanschool |awk '{split($0,a,"|"); print a[4]}')
        # if it returns 2 it has been approved
        if [[ "$lanschoolApproval" == '2' ]]
            then
                result="Approved"
        # If it returns 0 is has not been approved
        elif [[ "$lanschoolApproval" == '0' ]]
            then
                result="Not Approved"
        fi
fi
echo "<result>$result</result>"
