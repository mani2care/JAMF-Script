#!/bin/sh

###
#
#            Name:  Remove Printers.sh
#     Description:  Removes all printers.

########## main process ##########



# Remove all printers listed via lpstat.
/usr/bin/lpstat -p | /usr/bin/awk '{print $2}' | while read -r printer; do
  echo "Deleting printer: $printer"
  /usr/sbin/lpadmin -x "$printer"
done



exit 0
