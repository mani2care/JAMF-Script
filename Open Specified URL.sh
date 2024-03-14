#!/bin/sh

###
#
#            Name:  Open Specified URL.sh
#     Description:  Opens specified URL in system default browser.

########## variable-ing ##########

# Jamf Pro script parameter "URL"
targetURL="$4"

########## function-ing ##########

# Exits if any required Jamf Pro arguments are undefined.
check_jamf_pro_arguments () {
  if [ -z "$targetURL" ]; then
    echo "❌ ERROR: Undefined Jamf Pro argument, unable to proceed."
    exit 74
  fi
}

########## main process ##########

# Exit if any required Jamf Pro arguments are undefined.
check_jamf_pro_arguments


# Opens specified URL.
/usr/bin/open "$targetURL"

exit 0
