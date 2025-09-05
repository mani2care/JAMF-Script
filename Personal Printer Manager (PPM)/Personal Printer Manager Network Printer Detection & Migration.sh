#!/bin/bash
# Author: Manikandan
# Purpose: Validate organization printers, check org Printer Portal reachability, and handle migration

PRINTER_PORTAL="https://cloudprinter.com" #change your printer server name
Printer_policy="instappm" # change your package installer custome parameter here to call the policy to install the package.
# --- Functions ---

# Function to check if any printer with org.com exists
get_org_printers() {
  lpstat -v 2>/dev/null | grep -i "org.com"
}

# Function to check Printer Portal (with retries)
check_portal() {
  local max_retries=3
  local count=1
  while [[ $count -le $max_retries ]]; do
    STATUS_CODE=$(curl -k --silent --max-time 5 --output /dev/null --write-out "%{http_code}" "$PRINTER_PORTAL")
    if [[ "$STATUS_CODE" == "200" ]]; then
      return 0
    else
      echo "⚠️ Attempt $count: $PRINTER_PORTAL not reachable (HTTP $STATUS_CODE). Retrying in 10s..."
      sleep 10
    fi
    ((count++))
  done
  return 1
}

# --- Main script ---

echo "� Checking installed printers..."
org_printers=$(get_org_printers)

if [[ -n "$org_printers" ]]; then
  echo "✅ org printer(s) detected:"
  echo "$org_printers"

  echo "� Checking reachability to org Printer Portal..."
  if check_portal; then
    echo "✅ Network reachable. Installing org printer via Jamf..."
    jamf policy -event "$Printer_policy"
  else
    echo "❌ Org Printer Portal not reachable. User may not be on Org network."
    exit 1
  fi

else
  echo "ℹ️ No Org printer URL found in list."

  # Check if any printer exists at all
  if lpstat -v >/dev/null 2>&1 && [[ -n "$(lpstat -v)" ]]; then
    echo "⚠️ User seems to have a personal printer installed. No action taken."
  else
    echo "� No printers installed. Checking Org Printer Portal..."
    	jamf policy -event "$Printer_policy"
  fi
fi

exit 0
