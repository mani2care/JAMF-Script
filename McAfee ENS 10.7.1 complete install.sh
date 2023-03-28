#!/bin/bash
## postinstall

# McAfeeENS10.7.1postinstall.bash
# by Steve Dagley <@sdagley Jamf Nation/Twitter/MacAdmins Slack/GitHub>

# postinstall script for single install package for complete install of McAfee ENS 10.7.1
#
# Incorporate RipOff_Mcafee V2.1 script from MacAdmins Slack #mcafee channel
#
# Requires the package to leave the individual module components in
#	/var/tmp/McAfee/Agent/
#	/var/tmp/McAfee/ENS_TP/
#	/var/tmp/McAfee/ENS_FW/
#	/var/tmp/McAfee/ENS_ATP/
#	/var/tmp/McAfee/DEGO/
#	/var/tmp/McAfee/MNE/
#	/var/tmp/McAfee/FRP/
#
# Flags used in this script
#	/tmp/InstallKextFree	-	If this file exists installs components in KextFree mode
#								NOTE: This flag is now forced on in the script as I see no reason to install
#										ENS in kext mode these days. If you require kext mode remove the line
#										below that reads '/usr/bin/touch /tmp/InstallKextFree'
#	/tmp/SkipMNE			-	If this file exiss then skip installing MNE component (originally added for installs on VMs)

# Files names for components
AgentInstaller="install.sh"
FRPInstaller="FRP-5-1-1-261.pkg"
DEGOInstaller="DEGO_osx_5-1-0-1.pkg"
MNEInstaller="MNE-osx-5-1-0-1.pkg"
TPInstaller="McAfee-Threat-Prevention-for-Mac-10.7.1-ePO-client-package-RTW-109.pkg"
FWInstaller="McAfee-Firewall-for-Mac-10.7.1-ePO-client-package-RTW-104.pkg"
ATPInstaller="McAfee-Adaptive-Threat-Protection-for-Mac-10.7.1-ePO-client-package-Release106.pkg"
DLPInstaller=""		# Not used currently

function RemoveENS() {
	# Remove any existing McAfee install and purge package receipts
	# from the RipOff-McAfee v2.1 by @scheb in MacAdmins Slack #mcafee channel
	/bin/echo " "
	/bin/echo "## Removing any existing ENS install"
	/bin/echo " "

	#get current user name and ID
	userName=$(/bin/echo 'show State:/Users/ConsoleUser' | /usr/sbin/scutil | /usr/bin/awk '/Name / { print $3 }')
	currentUserID=$(/usr/bin/id -u "$userName")


	# stop running processes
	echo "stopping running processes"
	/usr/local/McAfee/DlpAgent/bin/DlpAgentControl.sh mastop
	/usr/local/McAfee/AntiMalware/VSControl mastop
	/usr/local/McAfee/StatefulFirewall/bin/StatefullFirewallControl mastop
	/usr/local/McAfee/WebProtection/bin/WPControl mastop
	/usr/local/McAfee/atp/bin/ATPControl mastop
	/usr/local/McAfee/FRP/bin/FRPControl mastop
	/usr/local/McAfee/Mar/MarControl stop
	/usr/local/McAfee/mvedr/MVEDRControl stop
	/usr/local/McAfee/Mcp/bin/mcpcontrol.sh mastop
	/usr/local/McAfee/MNE/bin/MNEControl mastop
	/usr/local/McAfee/fmp/bin/fmp stop
	/opt/McAfee/dx/bin/dxlservice stop
	/Library/McAfee/agent/bin/maconfig -stop
	echo ""

	# unload kexts
	echo "unloading kexts"
	/sbin/kextunload /Library/Application\ Support/McAfee/AntiMalware/AVKext.kext
	/sbin/kextunload /Library/Application\ Support/McAfee/FMP/mfeaac.kext
	/sbin/kextunload /Library/Application\ Support/McAfee/FMP/FileCore.kext
	/sbin/kextunload /Library/Application\ Support/McAfee/FMP/FMPSysCore.kext
	/sbin/kextunload /Library/Application\ Support/McAfee/StatefulFirewall/SFKext.kext
	/sbin/kextunload /usr/local/McAfee/AntiMalware/Extensions/AVKext.kext
	/sbin/kextunload /usr/local/McAfee/StatefulFirewall/Extensions/SFKext.kext
	/sbin/kextunload /usr/local/McAfee/Mcp/MCPDriver.kext
	/sbin/kextunload /usr/local/McAfee/DlpAgent/Extensions/DLPKext.kext
	/sbin/kextunload /usr/local/McAfee/DlpAgent/Extensions/DlpUSB.kext
	/sbin/kextunload /usr/local/McAfee/fmp/Extensions/FileCore.kext
	/sbin/kextunload /usr/local/McAfee/fmp/Extensions/NWCore.kext
	/sbin/kextunload /usr/local/McAfee/fmp/Extensions/FMPSysCore.kext
	echo ""

	# unload launch items
	echo "unloading launch items"
	/bin/launchctl bootout system /Library/LaunchAgents/com.mcafee.McAfeeSafariHost.plist
	/bin/launchctl bootout system /Library/LaunchAgents/com.mcafee.menulet.plist
	/bin/launchctl bootout system /Library/LaunchAgents/com.mcafee.reporter.plist
	/bin/launchctl bootout system /Library/LaunchDaemons/com.mcafee.aac.plist
	/bin/launchctl bootout system /Library/LaunchDaemons/com.mcafee.agent.ma.plist
	/bin/launchctl bootout system /Library/LaunchDaemons/com.mcafee.agent.macmn.plist
	/bin/launchctl bootout system /Library/LaunchDaemons/com.mcafee.agent.macompat.plist
	/bin/launchctl bootout system /Library/LaunchDaemons/com.mcafee.dxl.plist
	/bin/launchctl bootout system /Library/LaunchDaemons/com.mcafee.ssm.Eupdate.plist
	/bin/launchctl bootout system /Library/LaunchDaemons/com.mcafee.ssm.ScanFactory.plist
	/bin/launchctl bootout system /Library/LaunchDaemons/com.mcafee.ssm.ScanManager.plist
	/bin/launchctl bootout system /Library/LaunchDaemons/com.mcafee.virusscan.fmpcd.plist
	/bin/launchctl bootout system /Library/LaunchDaemons/com.mcafee.virusscan.fmpd.plist
	/bin/launchctl bootout system /Library/LaunchDaemons/com.mcafee.agentMonitor.helper.plist
	/usr/bin/killall -c Menulet
	/usr/bin/killall -c "McAfee Agent Status Monitor"
	echo ""

	# TODO: Unload safari/finder/chrome extensions

	# rm program dirs
	echo "removing program dirs"
	/bin/rm -rf /usr/local/McAfee/
	/bin/rm -rf /opt/McAfee/
	/bin/rm -rf /Applications/DataLossPrevention.app/
	/bin/rm -rf /Applications/McAfee\ Endpoint\ Security\ for\ Mac.app/
	/bin/rm -rf /Applications/McAfee\ Endpoint\ Protection\ for\ Mac.app/
	/bin/rm -rf /Applications/Utilities/McAfee\ ePO\ Remote\ Provisioning\ Tool.app/
	echo ""

	# rm support dirs
	echo "removing support dirs"
	/bin/rm -rf /Users/Shared/.mcafee
	/bin/rm -rf /Library/Application\ Support/McAfee/
	/bin/rm -rf /Library/Documentation/Help/McAfeeSecurity*
	/bin/rm -rf /Library/Frameworks/AVEngine.framework/
	/bin/rm -rf /Library/Frameworks/VirusScanPreferences.framework/
	/bin/rm -rf /Library/Internet\ Plug-Ins/Web\ Control.plugin/
	/bin/rm -rf /Library/McAfee/
	/bin/rm -rf /Quarantine/
	echo ""

	# rm prefs/launch items
	echo "removing prefs and launch items"
	/bin/rm -f /Library/Preferences/com.mcafee*
	/bin/rm -f /Library/Preferences/.com.mcafee*
	/bin/rm -f /Library/LaunchDaemons/com.mcafee*
	/bin/rm -f /Library/LaunchAgents/com.mcafee*
	/bin/rm -rf /Library/StartupItems/cma/
	/bin/rm -f /private/etc/cma.conf
	/bin/rm -rf /private/etc/cma.d/
	/bin/rm -rf /private/etc/ma.d/
	/bin/rm -f /private/etc/init.d/dx
	/bin/rm -rf /private/var/McAfee/
	/bin/rm -rf /private/var/tmp/.msgbus/
	/bin/rm -rf /Users/$userName/Library/Containers/com.McAfee*
	/bin/rm -rf /Users/$userName/Library/Application\ Scripts/com.McAfee*
	/bin/rm -rf /Users/$userName/Library/Group\ Containers/group.com.Mcafee*
	/bin/rm -rf /Users/$userName/Library/Preferences/com.mcafee*
	/bin/rm -f /Library/Google/Chrome/NativeMessagingHosts/siteadvisor.mcafee.chrome.extension.json
	/bin/rm -f /Library/PrivilegedHelperTools/com.mcafee.agentMonitor.helper
	echo ""

	# rm logs
	echo "removing logs"
	/bin/rm -f /Library/Logs/Native\ Encryption.log
	/bin/rm -f /private/var/log/McAfeeSecurity.log*
	echo ""

	# TODO: loop through and get all hotfix receipts to remove

	# forget receipts
	echo "forgetting receipts"
	/usr/sbin/pkgutil --forget com.mcafee.dxl
	/usr/sbin/pkgutil --forget com.mcafee.mscui
	/usr/sbin/pkgutil --forget com.mcafee.mar
	/usr/sbin/pkgutil --forget com.mcafee.mvedr
	/usr/sbin/pkgutil --forget com.mcafee.pkg.FRP
	/usr/sbin/pkgutil --forget com.mcafee.pkg.MNE
	/usr/sbin/pkgutil --forget com.mcafee.pkg.StatefulFirewall
	/usr/sbin/pkgutil --forget com.mcafee.pkg.utility
	/usr/sbin/pkgutil --forget com.mcafee.pkg.WebProtection
	/usr/sbin/pkgutil --forget com.mcafee.ssm.atp
	/usr/sbin/pkgutil --forget com.mcafee.ssm.fmp
	/usr/sbin/pkgutil --forget com.mcafee.ssm.mcp
	/usr/sbin/pkgutil --forget com.mcafee.ssm.dlp
	/usr/sbin/pkgutil --forget com.mcafee.virusscan
	/usr/sbin/pkgutil --forget comp.nai.cmamac
	echo ""

	# remove users/groups
	echo "removing user and groups"
	/usr/bin/dscl . delete /Users/mfe
	/usr/bin/dscl . delete /Groups/mfe
	/usr/bin/dscl . delete /Groups/Virex
	echo ""
}

function InstallAgent() {
	/bin/echo " "
	/bin/echo "## Installing McAfee Agent"
	/bin/echo " "
	# Run install.sh with -i (Install) option
	/bin/bash "/var/tmp/McAfee/Agent/$AgentInstaller" -i
	/bin/sleep 10
}

function InstallThreatPrevention() {
	/bin/echo " "
	/bin/echo "## Installing ThreatPrevention"
	if [ -f /tmp/InstallKextFree ]
	then
		/bin/echo "##  KextFree Mode Enabled"
		/usr/bin/touch /tmp/kernelLess
	fi
	/bin/echo " "
	/usr/sbin/installer -verbose -pkg "/var/tmp/McAfee/ENS_TP/$TPInstaller" -target /
}

function InstallFirewall() {
	/bin/echo " "
	/bin/echo "## Installing Firewall"
	if [ -f /tmp/InstallKextFree ]
	then
		# The Firewall module doesn't actually support KextFree mode but maybe one day...
		/bin/echo "##  KextFree Mode Enabled"
		/usr/bin/touch /tmp/kernelLess
	fi
	/bin/echo " "

	# Set flag that prevents immediate firewall start and let policy enforcement start it
	/usr/bin/touch /tmp/turnOffFW

	/usr/sbin/installer -verbose -pkg "/var/tmp/McAfee/ENS_FW/$FWInstaller" -target /
	
	# Now remove the flag
	/bin/rm -f /tmp/turnOffFW
}

function InstallAdaptiveThreatProtection() {
	/bin/echo " "
	/bin/echo "## Installing AdaptiveThreatProtection"
	if [ -f /tmp/InstallKextFree ]
	then
		/bin/echo "##  KextFree Mode Enabled"
		/usr/bin/touch /tmp/kernelLess
	fi
	/bin/echo " "
	/usr/sbin/installer -verbose -pkg "/var/tmp/McAfee/ENS_ATP/$ATPInstaller" -target /
}

function InstallDEGO() {
	/bin/echo " "
	/bin/echo "## Installing DEGO"
	/bin/echo " "
	/usr/sbin/installer -verbose -pkg "/var/tmp/McAfee/DEGO/$DEGOInstaller" -target /
}

function InstallMNE() {
	if [ -f /tmp/SkipMNE ]
	then
		/bin/echo " "
		/bin/echo "Skipping MNE"
		/bin/echo " "
		/bin/rm -f /tmp/SkipMNE
	else
		/bin/echo " "
		/bin/echo "## Installing MNE"
		/bin/echo " "
		# Set flag that supresses configuration dialog
		/usr/bin/touch "/tmp/.mcafee_provision.tmp"

		/usr/sbin/installer -verbose -pkg "/var/tmp/McAfee/MNE/$MNEInstaller" -target /
	fi
}

function InstallFRP() {
	/bin/echo " "
	/bin/echo "## Installing FRP"
	/bin/echo " "
	/usr/sbin/installer -verbose -pkg "/var/tmp/McAfee/FRP/$FRPInstaller" -target /
}

/bin/echo " "
/bin/echo "## Starting McAfee ENS install"
/bin/echo " "

# Remove any previous install
RemoveENS

# Set KextFree flag so components capable of it will install in that Mode
/usr/bin/touch /tmp/InstallKextFree

# Install ENS components - sequence is important to ensure proper installation
InstallAgent
InstallFRP
InstallDEGO
InstallMNE
InstallThreatPrevention
InstallFirewall
InstallAdaptiveThreatProtection

# Remove KextFree flag if present
if [ -f /tmp/InstallKextFree ]
then
	/bin/rm -f /tmp/InstallKextFree
fi

# Install PrivilegedHelper and LaunchDaemon
helperPath="/Library/Application Support/McAfee/MSS/Applications/McAfee Agent Status Monitor.app/Contents/Library/LaunchServices/com.mcafee.agentMonitor.helper"
if [ -f "$helperPath" ]; then
	if [[ ! -d "/Library/PrivilegedHelperTools" ]]; then
		/bin/mkdir -p "/Library/PrivilegedHelperTools"
		/bin/chmod 755 "/Library/PrivilegedHelperTools"
		/usr/sbin/chown -R root:wheel "/Library/PrivilegedHelperTools"
	fi
	
	/bin/cp -f "$helperPath" "/Library/PrivilegedHelperTools"
	
	if [[ $? -eq 0 ]]; then
		/bin/chmod 755 "/Library/PrivilegedHelperTools/com.mcafee.agentMonitor.helper"
		
		# create the launchd plist
		helperPlistPath="/Library/LaunchDaemons/com.mcafee.agentMonitor.helper.plist"
		/bin/cat > "$helperPlistPath" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.mcafee.agentMonitor.helper</string>
	<key>MachServices</key>
	<dict>
		<key>com.mcafee.agentMonitor.helper</key>
		<true/>
	</dict>
	<key>Program</key>
	<string>/Library/PrivilegedHelperTools/com.mcafee.agentMonitor.helper</string>
	<key>ProgramArguments</key>
	<array>
		<string>/Library/PrivilegedHelperTools/com.mcafee.agentMonitor.helper</string>
	</array>
</dict>
</plist>
EOF

		/bin/chmod 644 "$helperPlistPath"
		/bin/launchctl bootstrap system "$helperPlistPath"
	fi

fi

## Start agent
/bin/echo " "
/bin/echo "## Starting McAfee Agent"
/bin/echo " "
/Library/McAfee/cma/scripts/ma start

/bin/sleep 20

## Make sure the agent is awake
/bin/echo " "
/bin/echo "## Say hello to McAfee server"
/bin/echo " "
/Library/McAfee/cma/bin/cmdagent -p

/bin/sleep 30

## Check for policy updates
/bin/echo " "
/bin/echo "## Checking for policy updates"
/bin/echo " "
/Library/McAfee/cma/bin/cmdagent -c

/bin/sleep 30

## Enforce policies
/bin/echo " "
/bin/echo "## Tell McAfee Agent to enforce policies"
/bin/echo " "
/Library/McAfee/cma/bin/cmdagent -e

# Remove the files we placed in /var/tmp
/bin/rm -rf /var/tmp/McAfee/

/bin/echo " "
/bin/echo "## McAfee ENS install is complete"
/bin/echo " "

exit 0
