#!/bin/zsh --no-rcs

# Purpose: Create a launch daemon and script to update inventory immediately.

# Script parameters from the Jamf Pro policy
organizationName="abb"
organizationReverseDomain="com.abbrecon"

# Create organization folder if necessary to house the jamf-recon.zsh script
/bin/mkdir -p "/Library/$organizationName" || {
    echo "Failed to create /Library/$organizationName directory."
    exit 1
}

# Create jamf-recon.zsh script
cat << 'EOF' > "/Library/$organizationName/jamf-recon.zsh"
#!/bin/zsh

# Update Jamf Pro inventory
/usr/local/bin/jamf recon -verbose

# Delete this script after execution
/bin/rm "/Library/$organizationName/jamf-recon.zsh"

# Attempt to delete enclosing directory if empty
/bin/rmdir "/Library/$organizationName" 2>/dev/null

# Delete the launch daemon plist
/bin/rm "/Library/LaunchDaemons/$organizationReverseDomain.jamf-recon.plist"

# Unload the launch daemon
/bin/launchctl remove "$organizationReverseDomain.jamf-recon"

exit 0
EOF

# Set correct ownership and permissions on jamf-recon.zsh script
/usr/sbin/chown root:wheel "/Library/$organizationName/jamf-recon.zsh" && /bin/chmod 755 "/Library/$organizationName/jamf-recon.zsh" || {
    echo "Failed to set permissions on /Library/$organizationName/jamf-recon.zsh"
}

# Create $organizationReverseDomain.jamf-recon.plist launch daemon
cat << EOF > "/Library/LaunchDaemons/$organizationReverseDomain.jamf-recon.plist"
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
	<integer>60</integer> <!-- Set to 1 minute interval for smoother performance -->
</dict>
</plist>
EOF

# Set correct ownership and permissions on launch daemon plist
/usr/sbin/chown root:wheel "/Library/LaunchDaemons/$organizationReverseDomain.jamf-recon.plist" && /bin/chmod 644 "/Library/LaunchDaemons/$organizationReverseDomain.jamf-recon.plist" || {
    echo "Failed to set permissions on /Library/LaunchDaemons/$organizationReverseDomain.jamf-recon.plist"
}

# Start launch daemon after installation
/bin/launchctl bootstrap system "/Library/LaunchDaemons/$organizationReverseDomain.jamf-recon.plist" && /bin/launchctl start "$organizationReverseDomain.jamf-recon" || {
    echo "Failed to start the launch daemon"
}

exit 0
