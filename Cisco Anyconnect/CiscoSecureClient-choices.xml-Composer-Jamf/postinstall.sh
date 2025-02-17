#!/bin/bash
## postflight
##
## 2024-11-03

pathToScript=$0
pathToPackage=$1
targetLocation=$2
targetVolume=$3

#PACKAGE_PATH is internal to installer environment.
# https://gist.github.com/rtrouton/002034a14e9d8f4f5b32cd4b0998bc01
echo "PACKAGE_PATH - \"$PACKAGE_PATH\""
PACKAGE_NAME=$( basename "$PACKAGE_PATH" .pkg )

doLog ()
{
	echo "$PACKAGE_NAME - $1"
	logger -is "$PACKAGE_NAME - $1"
}
# doLog "thevarname: $thevarname"

doCleanup ()
{
# dismount the volume
hdiutil detach "$DMG_MOUNT_VOL"
sleep 5

# clean up the payloads
rm -rf /private/tmp/$PACKAGE_NAME
}

# PACKAGE_PATH
doLog "PACKAGE_PATH: $PACKAGE_PATH"

# $PACKAGE_NAME
doLog "PACKAGE_NAME: $PACKAGE_NAME"

# get path to DMG
DMG_PATH=$( ls /private/tmp/$PACKAGE_NAME/*dmg )
doLog "DMG_PATH: $DMG_PATH"

# get path to choices.xml 
CHOICES_PATH=$( ls /private/tmp/$PACKAGE_NAME/*xml )
doLog "CHOICES_PATH: $CHOICES_PATH"

#test DMG_PATH and CHOICES_PATH both exist, and are files. If not, exit with error.
if [[ -f "$DMG_PATH" && -f "$CHOICES_PATH" ]]; then
	doLog "DMG_PATH and CHOICES_PATH exist - yay!"
	else
	doLog "Problems with DMG_PATH or CHOICES_PATH. Exiting."
	exit 2
fi

# mount DMG in file system, silently
hdiutil attach -nobrowse -quiet "$DMG_PATH"
sleep 5

# do thing to get volume name
DMG_MOUNT_VOL=$( df | cut -w -f9- | awk '/Cisco/{gsub(/\t/," "); print $0}' )
doLog "DMG_MOUNT_VOL: $DMG_MOUNT_VOL"

# get pkg name inside the volume
INSTALL_PKG=$( ls "$DMG_MOUNT_VOL"/*.pkg )
doLog "INSTALL_PKG: $INSTALL_PKG"

# test DMG_MOUNT_VOL exists and is directory; INSTALL_PKG exists and is file
if [[ -d "$DMG_MOUNT_VOL" && -f "$INSTALL_PKG" ]]; then
	doLog "DMG_MOUNT_VOL and INSTALL_PKG exist - yay!"
	else
	doLog "Problems with DMG_MOUNT_VOL or INSTALL_PKG. Exiting."
	exit 1
fi

# do the install thing
installer -applyChoiceChangesXML "$CHOICES_PATH" -pkg "$INSTALL_PKG" -target /

installResult=$?

if [[ $installResult != "0" ]]; then
	doLog "INSTALL PROBLEM: Exit $installResult"
	doCleanup
	exit $installResult
fi

doCleanup



#

#exit 0		## Success
#exit 1		## Failure
