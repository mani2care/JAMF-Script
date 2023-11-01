#!/bin/sh
# System_Prefs_Standard_Allow_Users_Access_v1.sh
#
##################################################
#
# key: SettingsExtensions
# 
# com.apple.Accessibility-Settings.extension
# com.apple.AirDrop-Handoff-Settings.extension
# com.apple.Battery-Settings.extension
# com.apple.BluetoothSettings
# com.apple.CD-DVD-Settings.extension
# com.apple.ClassKit-Settings.extension
# com.apple.Classroom-Settings.extension
# com.apple.ControlCenter-Settings.extension
# com.apple.Date-Time-Settings.extension
# com.apple.Desktop-Settings.extension
# com.apple.Displays-Settings.extension
# com.apple.ExtensionsPreferences
# com.apple.Family-Settings.extension
# com.apple.Focus-Settings.extension
# com.apple.Game-Center-Settings.extension
# com.apple.Game-Controller-Settings.extension
# com.apple.HeadphoneSettings
# com.apple.Internet-Accounts-Settings.extension
# com.apple.Keyboard-Settings.extension
# com.apple.Localization-Settings.extension
# com.apple.Lock-Screen-Settings.extension
# com.apple.LoginItems-Settings.extension
# com.apple.Mouse-Settings.extension
# com.apple.Network-Settings.extension
# com.apple.NetworkExtensionSettingsUI.NESettingsUIExtension
# com.apple.Notifications-Settings.extension
# com.apple.Passwords-Settings.extension
# com.apple.Print-Scan-Settings.extension
# com.apple.Screen-Time-Settings.extension
# com.apple.ScreenSaver-Settings.extension
# com.apple.Sharing-Settings.extension
# com.apple.Siri-Settings.extension
# com.apple.Software-Update-Settings.extension
# com.apple.Sound-Settings.extension
# com.apple.Startup-Disk-Settings.extension
# com.apple.Time-Machine-Settings.extension
# com.apple.Touch-ID-Settings.extension
# com.apple.Trackpad-Settings.extension
# com.apple.Transfer-Reset-Settings.extension
# com.apple.Users-Groups-Settings.extension
# com.apple.WalletSettingsExtension
# com.apple.Wallpaper-Settings.extension
# com.apple.settings.Storage
# com.apple.systempreferences.AppleIDSettings
# com.apple.wifi-settings-extension
#
##################################################
#
# Add staff to lpadmin group
/usr/sbin/dseditgroup -o edit -n /Local/Default -a everyone -t group lpadmin

# Unlock System Prefs first
/usr/bin/security authorizationdb write system.preferences allow

# Unlock Print and Fax
/usr/bin/security authorizationdb write system.preferences.printing allow
/usr/bin/security authorizationdb write system.print.operator allow

# Unlock Energy Saver
/usr/bin/security authorizationdb write system.preferences.energysaver allow

# Unlock WiFi
/usr/bin/security authorizationdb write com.apple.wifi allow
/usr/bin/security authorizationdb write system.preferences.network allow
/usr/bin/security authorizationdb write system.services.systemconfiguration.network allow

# Unlock Date and Time
/usr/bin/security authorizationdb write system.preferences.datetime allow
/usr/bin/security authorizationdb write system.preferences.dateandtime.changetimezone allow

exit
