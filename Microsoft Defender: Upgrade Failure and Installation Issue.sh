#!/bin/bash

echo "**** Current health ****"

if [ ! -f "/usr/local/bin/mdatp" ]; then
  echo "Defender not installed, nothing to do"
  exit 0
fi

/usr/local/bin/mdatp health
echo ""
/usr/local/bin/mdatp health --details tamper_protection

TP_MODE=$(/usr/local/bin/mdatp health --details tamper_protection --field tamper_protection)
if [ "$TP_MODE" != '"block"' ]; then
  echo "Tamper Protection is not in the block mode, nothing to do"
  exit 0
fi

if [ -r "/Library/Managed Preferences/com.microsoft.wdav.plist" ]; then
  sudo cp "/Library/Managed Preferences/com.microsoft.wdav.plist" "/tmp/com.microsoft.wdav.plist"
  sudo rm "/Library/Managed Preferences/com.microsoft.wdav.plist"
fi

if [ -r "/Library/Preferences/com.microsoft.mdeattach.plist" ]; then
  sudo cp "/Library/Preferences/com.microsoft.mdeattach.plist" "/tmp/com.microsoft.mdeattach.plist"
  sudo rm "/Library/Preferences/com.microsoft.mdeattach.plist"
fi

if [ -r "/Library/Managed Preferences/com.microsoft.wdav.ext.plist" ]; then
  sudo cp "/Library/Managed Preferences/com.microsoft.wdav.ext.plist" "/tmp/com.microsoft.wdav.ext.plist"
  sudo rm "/Library/Managed Preferences/com.microsoft.wdav.ext.plist"
fi

sleep 10

TP_OLD_MODE=$(/usr/local/bin/mdatp health --details tamper_protection --field configuration_local)
sudo /usr/local/bin/mdatp config tamper-protection enforcement-level --value audit

echo ""
echo "**** New health ****"
/usr/local/bin/mdatp health
echo ""
/usr/local/bin/mdatp health --details tamper_protection

echo ""
echo "**** Upgrading Defender ****"

curl -o /tmp/wdav.pkg https://officecdnmac.microsoft.com/pr/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/wdav.pkg
sudo installer -pkg /tmp/wdav.pkg -target /
sudo rm /tmp/wdav.pkg

echo ""
echo "**** After upgrade ****"
/usr/local/bin/mdatp health
echo ""
/usr/local/bin/mdatp health --details tamper_protection

if [ -r "/tmp/com.microsoft.wdav.plist" ]; then
  sudo cp "/tmp/com.microsoft.wdav.plist" "/Library/Managed Preferences/com.microsoft.wdav.plist"
  sudo rm "/tmp/com.microsoft.wdav.plist"
fi

if [ -r "/tmp/com.microsoft.mdeattach.plist" ]; then
  sudo cp "/tmp/com.microsoft.mdeattach.plist" "/Library/Preferences/com.microsoft.mdeattach.plist"
  sudo rm "/tmp/com.microsoft.mdeattach.plist"
fi

if [ -r "/tmp/com.microsoft.wdav.ext.plist" ]; then
  sudo cp "/tmp/com.microsoft.wdav.ext.plist" "/Library/Managed Preferences/com.microsoft.wdav.ext.plist"
  sudo rm "/tmp/com.microsoft.wdav.ext.plist"
fi

if [ "$TP_OLD_MODE" == "unavailable" ]; then
  echo "sudo /usr/local/bin/mdatp config tamper-protection enforcement-level --value default"
  sudo /usr/local/bin/mdatp config tamper-protection enforcement-level --value default
else
  TP_OLD_MODE=$(echo "$TP_OLD_MODE" | tr -d '"')
  echo "sudo /usr/local/bin/mdatp config tamper-protection enforcement-level --value $TP_OLD_MODE"
  sudo /usr/local/bin/mdatp config tamper-protection enforcement-level --value $TP_OLD_MODE
fi

sleep 10

echo ""
echo "**** After restore ****"
/usr/local/bin/mdatp health
echo ""
/usr/local/bin/mdatp health --details tamper_protection
