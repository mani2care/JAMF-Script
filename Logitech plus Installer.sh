#!/bin/bash

#https://hub.sync.logitech.com/syncguides/post/install-sync-on-mac-with-jamf-9VLtbmduyMB0vzQ
#https://prosupport.logi.com/hc/hu/articles/1500002995241-Mass-installation-and-configuration-of-Logitech-Options
#https://hub.sync.logitech.com/options/post/options-mass-installation-macos-2m9kVszkzbfpYEJ
#https://support.logi.com/hc/en-za/articles/26832619554711-How-to-completely-uninstall-Logi-Options-and-Options
#https://gist.github.com/ashu17706/196fe586433778c2ef4d92fd7402a553

#insted uninstalling use the parameter --uninstall
/Library/Application\ Support/Logitech.localized/LogiOptionsPlus/logioptionsplus_agent.app/Contents/Frameworks/logioptionsplus_updater.app/Contents/MacOS/logioptionsplus_updater --full --uninstall

/private/tmp/Logitech/Logitech_Installer.app/Contents/MacOS/logioptionsplus_installer --quiet --update No --analytics No --flow No --log /private/tmp

#--uninstall --sso No --backlight" = 1; "--device-recommendation" = 1; "--dfu" = 1; "--flow" = 1; "--logivoice" = 1; "--smartactions" = 1;
#https://hub.sync.logitech.com/options/post/options-silent-installation-feature-flags-RnX8O7v5xTQ41mq
sleep 5
rm -rf /private/tmp/Logitech

exit
