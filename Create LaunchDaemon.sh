#!/bin/sh
# Create a LaunchDaemon to launch SYM

	/bin/echo "<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>Label</key>
		<string>com.depnotify</string>
		<key>UserName</key> 
		<string>root</string>
		<key>ProgramArguments</key>
		<array>
			<string>/usr/local/jamf/bin/jamf</string>
			<string>policy</string>
			<string>-event</string>
			<string>suymsc</string>
			<string>-randomDelaySeconds</string>
			<string>10</string>
		</array>
		<key>RunAtLoad</key> 
		<true/>
        <key>LaunchOnlyOnce</key>
        <true/>
	</dict>
	</plist>" > /Library/LaunchDaemons/com.depnotify.plist 
	
    sudo chown root:wheel /Library/LaunchDaemons/com.depnotify.plist
	sudo chmod 755 /Library/LaunchDaemons/com.depnotify.plist
 
	
