#!/bin/bash
preference_path='/Library/Managed Preferences/com.abb.deviceinfo.plist'
preference_key='site_name'

read_Key=$(defaults read "${preference_path}" "${preference_key}")
echo "<result>$read_Key</result>"
