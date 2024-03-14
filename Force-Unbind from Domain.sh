#!/bin/sh

###
#
#            Name:  Force-Unbind from Domain.sh
#     Description:  Forces an unbind from Active Directory domain.

########## main process ##########

# Remove domain bind from computer. Runs with -force to not require a working domain connection to complete the action.
# Note that real AD credentials are not required for a force-unbind.
/usr/sbin/dsconfigad -remove -username "NotReal" -password "NotReal" -force

exit 0
