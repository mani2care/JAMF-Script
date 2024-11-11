#!/bin/zsh --no-rcs

#Purpose: create a launch daemon and script to update inventory immediately.

# script parameters from the Jamf Pro policy
organizationName="abb"
organizationReverseDomain="com.abbrecon"


# create organization folder if necessary to house the jamf-recon.zsh script

/bin/mkdir -p "/Library/$organizationName"

# create jamf-recon.zsh script

tee "/Library/$organizationName/jamf-recon.zsh" << EOF
#!/bin/zsh

# update Jamf Pro inventory
/usr/local/bin/jamf recon -verbose

# delete this script
/bin/rm "/Library/$organizationName/jamf-recon.zsh"

# attempt to delete enclosing directory
/bin/rmdir "/Library/$organizationName"

# delete the launch daemon plist
/bin/rm "/Library/LaunchDaemons/$organizationReverseDomain.jamf-recon.plist"

# kill the launch daemon process
/bin/launchctl remove "$organizationReverseDomain.jamf-recon"

exit 0
EOF

# set correct ownership and permissions on jamf-recon.zsh script

/usr/sbin/chown root:wheel "/Library/$organizationName/jamf-recon.zsh" && /bin/chmod +x "/Library/$organizationName/jamf-recon.zsh"

# create $organizationReverseDomain.jamf-recon.plist launch daemon

tee /Library/LaunchDaemons/$organizationReverseDomain.jamf-recon.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>EnvironmentVariables</key>
	<dict>
		<key>PATH</key>
		<string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
	</dict>
	<key>Label</key>
	<string>$organizationReverseDomain.jamf-recon</string>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/zsh</string>
		<string>-c</string>
		<string>"/Library/$organizationName/jamf-recon.zsh"</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>StartInterval</key>
	<integer>1</integer>
</dict>
</plist>
EOF

# set correct ownership and permissions on launch daemon

/usr/sbin/chown root:wheel /Library/LaunchDaemons/$organizationReverseDomain.jamf-recon.plist && /bin/chmod 644 /Library/LaunchDaemons/$organizationReverseDomain.jamf-recon.plist

# start launch daemon after installation

/bin/launchctl bootstrap system /Library/LaunchDaemons/$organizationReverseDomain.jamf-recon.plist && /bin/launchctl start /Library/LaunchDaemons/$organizationReverseDomain.jamf-recon.plist

exit
