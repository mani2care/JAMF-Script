#!/bin/bash

# /v1/managed-software-updates/update-statuses

# Define file paths
jsonFilePath="$HOME/Downloads/AllUpdatesFinal.json"
csvFilePath="$HOME/Downloads/DeviceUpdates.csv"
tempJsonFile="$HOME/Downloads/TempUpdates.json"
deviceIdList="/tmp/Update_Reporting/deviceIdList.txt"
mkdir -p /tmp/Update_Reporting

# API Credentials
jamfProAPIClient="${JAMF_API_CLIENT}"
jamfProAPISecret="${JAMF_API_SECRET}"
jamfProURL="https://uc-me-002.bb.com:8443"

# Bearer Token Auth Variables
token=""
tokenExpirationEpoch="0"

# Function to clean old files
cleanOldFiles() {
    echo "Cleaning old data files..."
    rm -f "$jsonFilePath" "$csvFilePath" "$tempJsonFile" "$deviceIdList"
    > "$deviceIdList"
}

# Function to get Bearer Token
getBearerToken() {
    echo "Requesting authentication token..."
    curl_response=$(curl --silent --location --request POST "${jamfProURL}/api/oauth/token" \
        --header "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "client_id=${jamfProAPIClient}" \
        --data-urlencode "grant_type=client_credentials" \
        --data-urlencode "client_secret=${jamfProAPISecret}")

    if echo "${curl_response}" | jq -e .access_token >/dev/null 2>&1; then
        token=$(echo "${curl_response}" | jq -r '.access_token')
        echo "Authentication token successfully generated"
    else
        echo "Auth Error: Failed to retrieve access token. Verify Client ID and Secret."
        exit 1
    fi
}

# Function to invalidate Bearer Token
invalidateToken() {
    if [[ -n "$token" ]]; then
        responseCode=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${token}" \
            "${jamfProURL}/api/v1/auth/invalidate-token" -X POST)

        if [[ ${responseCode} == 204 ]]; then
            echo "Token successfully invalidated"
            token=""
        else
            echo "An error occurred while invalidating the token."
        fi
    fi
}

# Function to fetch update plans with pagination
fetchUpdatePlans() {
    local pageSize="100"
    local page="0"
    local totalPossibleResults=0
    local filterGetCountOfResults=1

    echo "Fetching update plans from Jamf Pro..."
    while [ $totalPossibleResults -lt $filterGetCountOfResults ]; do
        #response=$(curl -s -X 'GET' \
        #    "$jamfProURL/api/v1/managed-software-updates/plans?page=$page&page-size=$pageSize&sort=planUuid%3Adesc" \
        #    -H 'accept: application/json' \
        #    -H "Authorization: Bearer $token")

        response=$(curl -s -X 'GET' \
            "$jamfProURL/api/v1/managed-software-updates/update-statuses" \
            -H 'accept: application/json' \
            -H "Authorization: Bearer $token")

        if [[ -z "$response" || "$response" == "null" ]]; then
            echo "Error: API response is empty or null. Exiting."
            exit 1
        fi

        echo "$response" > "$tempJsonFile"
        cat "$tempJsonFile" >> "$jsonFilePath"

        filterGetCountOfResults=$(jq -r '.totalCount' <<< "$response")
        totalPossibleResults=$(( (page + 1) * pageSize ))
        ((page++))
    done
    echo "Update plans retrieved successfully."
}

# Function to extract device details and convert to CSV
processUpdatePlans() {
    echo "Processing data and converting to CSV format..."
   # echo "Device_ID,Computer,updateAction,status,Error_Reason" > "$csvFilePath"
   # jq -r '.results[] | [.device.deviceId, .device.objectType, .updateAction, .status.state, .status.errorReasons[0]] | @csv' "$jsonFilePath" >> "$csvFilePath"

 # Write header to CSV
echo "Device_ID,Computer,ProductKey,MaxDeferrals,DeferralsRemaining,DownloadPercentComplete,Downloaded,NextScheduledInstall,Status,Created,Updated" > "$csvFilePath"

# Extract data and append to CSV
jq -r '.results[] | 
  [.device.deviceId, 
   .device.objectType, 
   .productKey, 
   .maxDeferrals, 
   .deferralsRemaining, 
   .downloadPercentComplete, 
   .downloaded, 
   .nextScheduledInstall, 
   .status, 
   .created, 
   .updated] | @csv' "$jsonFilePath" >> "$csvFilePath"
}

# Function to remove duplicate device IDs from CSV
filterUniqueEntries() {
    echo "Filtering unique device entries..."
    finalCSVOutput="$HOME/Downloads/FilteredDeviceUpdates.csv"
    > "$finalCSVOutput"

    while IFS= read -r line; do
        deviceID=$(echo "$line" | awk -F, '{print $1}')
        if ! grep -q "$deviceID" "$deviceIdList"; then
            echo "$deviceID" >> "$deviceIdList"
            echo "$line" >> "$finalCSVOutput"
        fi
    done < "$csvFilePath"

    mv "$finalCSVOutput" "$csvFilePath"
}

# Main Execution
cleanOldFiles
getBearerToken
fetchUpdatePlans
processUpdatePlans
filterUniqueEntries
invalidateToken

rm -rf ~/Downloads/TempUpdates.json
rm -rf /tmp/Update_Reporting

echo "Process completed. Check $csvFilePath for results."
