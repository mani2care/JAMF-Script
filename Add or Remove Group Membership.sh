#!/bin/sh

###
#
#            Name:  Add or Remove Group Membership.sh
#     Description:  Adds target user or group to specified group membership, or removes said membership.

########## variable-ing ##########



# Jamf Pro script parameter: "Target ID"
targetID="${4}"
# Jamf Pro script parameter: "Target Type"
# Must be either "user" or "group".
targetType="${5}"
# Jamf Pro script parameter: "Target Membership"
# Enter the name of a user group.
targetMembership="${6}"
# Jamf Pro script parameter: "Script Action"
# Must be either "add" or "remove".
scriptAction="${7}"



########## function-ing ##########



# Exits if any required Jamf Pro arguments are undefined.
check_jamf_pro_arguments () {

  if [ -z "$targetID" ] || [ -z "$targetType" ] || [ -z "$targetMembership" ] || [ -z "$scriptAction" ]; then
    echo "❌ ERROR: Undefined Jamf Pro argument, unable to proceed."
    exit 74
  fi

}



########## main process ##########



# Verify script prerequisites.
check_jamf_pro_arguments


# Populate binary arguments for specified script action, or exit if undefined.
if [ "$scriptAction" = "add" ]; then
  actionFlag="a"
elif [ "$scriptAction" = "remove" ]; then
  actionFlag="d"
else
  echo "❌ ERROR: Script Action is unexpected value, unable to proceed. Please check Script Action parameter in Jamf Pro policy."
  exit 1
fi


# Exit if Target Type is an incorrect value.
if [ "$targetType" != "user" ] && [ "$targetType" != "group" ]; then
  echo "❌ ERROR: Target Type ${targetType} is unexpected value, unable to proceed. Please check Target Type parameter in Jamf Pro policy."
  exit 1
fi


# Exit if specified group does not exist.
if ! /usr/sbin/dseditgroup -o read "$targetMembership" 1>"/dev/null"; then
  echo "Specified group (${targetMembership}) does not exist, no action required."
  exit 0
elif [ "$targetType" = "user" ]; then
  if /usr/sbin/dseditgroup -o checkmember -m "$targetID" "$targetMembership"; then
    # If action is add, exit if target user is already in the specified group.
    if [ "$scriptAction" = "add" ]; then
      echo "Target user is already a member of ${targetMembership}, no action required."
      exit 0
    fi
  else
    # If action is remove, exit if target user is not in the specified group.
    if [ "$scriptAction" = "remove" ]; then
      echo "Target user is not a member of ${targetMembership}, no action required."
      exit 0
    fi
  fi
fi


# Add or remove target user or group to or from target group membership.
/usr/sbin/dseditgroup -o edit \
  -"$actionFlag" "$targetID" \
  -t "$targetType" \
  "$targetMembership"
echo "Modified ${targetID} group membership for ${targetMembership} (action: ${scriptAction})."


exit 0
