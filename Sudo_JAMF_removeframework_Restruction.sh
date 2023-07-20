#!/bin/bash

# Identify the username of the logged-in user

currentUser=`defaults read /Library/Preferences/com.apple.loginwindow lastUserName`

# Create file named "standard" and place in /private/tmp/

touch /private/tmp/standard 

# Populate "standard" file with desired permissions

echo "$currentUser	ALL= (ALL) ALL
$currentUser	ALL= !/usr/local/bin/jamf" >> /private/tmp/standard

#$currentUser	ALL= !/usr/bin/passwd root, !/usr/bin/defaults, !/usr/sbin/visudo, !/usr/bin/vi /etc/sudoers, !/usr/bin/vi /private/etc/sudoers, !/usr/bin/sudo -e /etc/sudoers, !/usr/bin/sudo -e /private/etc/sudoers, !/usr/local/bin/jamf" >> /private/tmp/standard
# Move "standard" file to /etc/sudoers.d

mv /private/tmp/standard /etc/sudoers.d

# Change permissions for "standard" file

chmod 644 /etc/sudoers.d/standard

exit 0;		## Sucess
exit 1;		## Failure


#To restore the access 

#rm /etc/sudoers.d/standard

#exit 0;		## Sucess
#exit 1;		## Failure