#!/bin/bash
# shellcheck disable=SC2086

###
#
#            Name:  Update Proxy Bypass Domain.sh
#     Description:  For each network interface with a proxy bypass domain entry
#                   of "*.local", changes to the target domain entry.

########## variable-ing ##########



# Jamf Pro script parameter "Proxy Bypass Domain".
# Should be in the format "*.domain".
targetDomain="$4"
networkInterfaces=$(/usr/sbin/networksetup -listallnetworkservices | "/usr/bin/sed" 1d)



########## function-ing ##########



# Exits if any required Jamf Pro arguments are undefined.
function check_jamf_pro_arguments {
  jamfArguments=(
    "$targetDomain"
  )
  for argument in "${jamfArguments[@]}"; do
    if [[ "$argument" = "" ]]; then
      echo "❌ ERROR: Undefined Jamf Pro argument, unable to proceed."
      exit 74
    fi
  done
}



########## main process ##########



# Exit if any required Jamf Pro arguments are undefined.
check_jamf_pro_arguments



# Replace all instances of "*.local" in each network interface with "$targetDomain".
while IFS= read -r interface; do
  bypassDomainsCurrent=$(/usr/sbin/networksetup -getproxybypassdomains "$interface")
  if [[ "$bypassDomainsCurrent" = *"$targetDomain"* ]]; then
    echo "$interface already inclues $targetDomain as proxy bypass domain, no action required."
  elif [[ "$bypassDomainsCurrent" = *"There aren't any bypass domains set on"* ]]; then
    echo "No proxy bypass domains defined for $interface, no action required."
  else
    bypassDomainsUpdate=$(echo "$bypassDomainsCurrent" | /usr/bin/sed "s/*.local/$targetDomain/" | /usr/bin/tr "\n" " ")
    /usr/sbin/networksetup -setproxybypassdomains "$interface" $bypassDomainsUpdate
    echo "Updated proxy bypass domains for $interface: $bypassDomainsUpdate"
  fi
done <<< "$networkInterfaces"



exit 0
