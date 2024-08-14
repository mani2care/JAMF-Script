#!/bin/sh

siteName=$(profiles -P -o stdout | grep -i -A 20 "User Info" | grep "site_name" | awk -F'=' '{gsub(/^ *| *$/,"",$2); print $2}' | tr -d ';' 2>/dev/null)
echo $siteName
if [[ $siteName ]]; then
   echo "<result>${siteName}</result>"
else
   echo "<result>Not_Available</result>"
fi