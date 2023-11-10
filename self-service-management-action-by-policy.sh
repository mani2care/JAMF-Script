#!/bin/bash
#     Description:  This script is designed to run with policies to use
#                   Management Action.app to send a push notification to 
#                   a managed Mac.
title=""            #	"string"
subtitle=""         #	"string"
message=""          #	"string"

[ "$4" != "" ] && [ "$title" == "" ] && title=$4
[ "$5" != "" ] && [ "$subtitle" == "" ] && subtitle=$5
[ "$6" != "" ] && [ "$message" == "" ] && message=$6

"/Library/Application Support/JAMF/bin/Management Action.app/Contents/MacOS/Management Action" -title "$title" -subtitle "$subtitle" -message "$message"

exit 0
