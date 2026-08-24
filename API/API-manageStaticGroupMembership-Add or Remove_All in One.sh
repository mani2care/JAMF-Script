#!/bin/zsh --no-rcs
####################################################################################################
# Script Name:    manageStaticGroupMembership.zsh
# Author:         Manikandan R (https://github.com/mani2care)
# Team:           JAMF
# Version:        2.0
# Created:        2026-08-24
# Modified:       2026-08-24
#
# Description:
#   Adds or removes Mac(s) from a Jamf Pro static computer group via the
#   Classic API, authenticating with an OAuth client credentials API role
#   (required privileges: Update Static Computer Groups, Read Computers).
#
#   Two mutually exclusive source modes, selected by $8:
#     "local" - reads the serial number of the Mac the script is running on
#               (via ioreg) and acts on just that device.
#     "file"  - reads a list of serial numbers (one per line) from a .txt
#               file at the path given in $9, and acts on every matching
#               device.
#
#   Action, selected by $10:
#     "add"    - adds the resolved device(s) to STATIC_GROUP_ID.
#     "remove" - removes the resolved device(s) from STATIC_GROUP_ID.
#
# Jamf Parameters:
#   $4   CLIENT_ID          - API client ID
#   $5   CLIENT_SECRET      - API client secret
#   $6   STATIC_GROUP_ID    - Target static computer group ID
#   $7   JAMF_URL           - e.g. https://yourinstance.jamfcloud.com  (no trailing slash)
#   $8   MODE               - "local" or "file"
#   $9   SERIAL_LIST_PATH   - Path to .txt file of serial numbers (required only when MODE=file)
#   $10  ACTION             - "add" or "remove"
#
# Change History:
#   1.0  2026-08-24  Manikandan R  Initial version - local + file list modes,
#                                  HTTP-status-based add validation, shared logging.
#   2.0  2026-08-24  Manikandan R  Added ACTION parameter (add/remove) so a single
#                                  script handles both group membership directions.
####################################################################################################

#CLIENT_ID="$4"
#CLIENT_SECRET="$5"
#STATIC_GROUP_ID="$6"
#JAMF_URL="${7%/}"
#MODE="$8"
#SERIAL_LIST_PATH="$9"
#ACTION="${10}"

LOG_FILE="/Users/Shared/manageStaticGroupMembership.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

####################################################################################################
# Validate inputs
####################################################################################################

if [[ -z "$CLIENT_ID" || -z "$CLIENT_SECRET" || -z "$STATIC_GROUP_ID" || -z "$JAMF_URL" ]]; then
    log "ERROR: Missing one or more required parameters (CLIENT_ID, CLIENT_SECRET, STATIC_GROUP_ID, JAMF_URL)."
    exit 1
fi

if [[ "$MODE" != "local" && "$MODE" != "file" ]]; then
    log "ERROR: MODE (\$8) must be 'local' or 'file'. Got: '$MODE'"
    exit 1
fi

if [[ "$ACTION" != "add" && "$ACTION" != "remove" ]]; then
    log "ERROR: ACTION (\$10) must be 'add' or 'remove'. Got: '$ACTION'"
    exit 1
fi

if [[ "$MODE" == "file" ]]; then
    if [[ -z "$SERIAL_LIST_PATH" ]]; then
        log "ERROR: MODE is 'file' but SERIAL_LIST_PATH (\$9) was not provided."
        exit 1
    fi
    if [[ ! -f "$SERIAL_LIST_PATH" ]]; then
        log "ERROR: Serial list file not found at path: $SERIAL_LIST_PATH"
        exit 1
    fi
fi

log "MODE: $MODE"
log "ACTION: $ACTION"
log "STATIC_GROUP_ID: $STATIC_GROUP_ID"
log "JAMF_URL: $JAMF_URL"

####################################################################################################
# Authenticate
####################################################################################################

AUTH_RESPONSE=$(curl --location --request POST "$JAMF_URL/api/oauth/token" \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode "client_id=$CLIENT_ID" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "client_secret=$CLIENT_SECRET" \
    --silent)

if [[ "$AUTH_RESPONSE" == *"access_token"* ]]; then
    log "Auth Response: Successfully retrieved access token"
else
    log "Auth Response: Failed to retrieve access token"
    log "Response: $AUTH_RESPONSE"
    exit 1
fi

ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

if [[ -z "$ACCESS_TOKEN" ]]; then
    log "ERROR: Access token parsed as empty despite auth response containing 'access_token'."
    exit 1
fi

####################################################################################################
# Functions: look up device ID by serial, add/remove device ID from static group
####################################################################################################

get_device_id() {
    local serial="$1"
    local device_id

    device_id=$(curl -s -H "Accept: text/xml" -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        "${JAMF_URL}/JSSResource/computers/serialnumber/${serial}" | \
        xmllint --xpath '/computer/general/id/text()' - 2>/dev/null)

    echo "$device_id"
}

modify_group_membership() {
    local device_id="$1"
    local serial="$2"
    local xml_header="<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    local api_data
    local http_status
    local response_body
    local tmp_response

    if [[ "$ACTION" == "add" ]]; then
        api_data="<computer_group><id>${STATIC_GROUP_ID}</id><computer_additions><computer><id>${device_id}</id></computer></computer_additions></computer_group>"
    else
        api_data="<computer_group><id>${STATIC_GROUP_ID}</id><computer_deletions><computer><id>${device_id}</id></computer></computer_deletions></computer_group>"
    fi

    tmp_response=$(mktemp)

    http_status=$(curl -s -o "$tmp_response" -w "%{http_code}" \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: text/xml" \
        --url "${JAMF_URL}/JSSResource/computergroups/id/${STATIC_GROUP_ID}" \
        --data "${xml_header}${api_data}" \
        --request PUT)

    response_body=$(cat "$tmp_response")
    rm -f "$tmp_response"

    if [[ "$http_status" == "201" || "$http_status" == "200" ]]; then
        log "Successfully ${ACTION}ed device ID ${device_id} (serial: ${serial}) $([[ "$ACTION" == "add" ]] && echo "to" || echo "from") static group ${STATIC_GROUP_ID}."
        return 0
    else
        log "Failed to ${ACTION} device ID ${device_id} (serial: ${serial}). HTTP status: ${http_status}"
        log "Response: ${response_body}"
        return 1
    fi
}

process_serial() {
    local serial="$1"
    local device_id

    if [[ -z "$serial" ]]; then
        return
    fi

    device_id=$(get_device_id "$serial")

    if [[ -z "$device_id" ]]; then
        log "WARNING: No Jamf device ID found for serial: ${serial} - skipping."
        return
    fi

    log "Serial ${serial} resolved to Device ID ${device_id}"
    modify_group_membership "$device_id" "$serial"
}

####################################################################################################
# Mode: local - resolve this Mac's own serial number and act on it
####################################################################################################

if [[ "$MODE" == "local" ]]; then
    SERIAL_NUMBER=$(ioreg -l | awk '/IOPlatformSerialNumber/ { print $4; }' | sed 's/"//g')

    if [[ -z "$SERIAL_NUMBER" ]]; then
        log "ERROR: Could not determine local serial number via ioreg."
        exit 1
    fi

    log "Local Serial Number: $SERIAL_NUMBER"
    process_serial "$SERIAL_NUMBER"
fi

####################################################################################################
# Mode: file - read serial numbers (one per line) from SERIAL_LIST_PATH and act on each
####################################################################################################

if [[ "$MODE" == "file" ]]; then
    log "Reading serial numbers from: $SERIAL_LIST_PATH"

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Trim whitespace, skip blank lines and comment lines starting with #
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" || "$line" == \#* ]] && continue

        process_serial "$line"
    done < "$SERIAL_LIST_PATH"
fi

log "Script completed."
exit 0
