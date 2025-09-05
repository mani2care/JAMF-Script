#!/bin/bash
# Author: Manikandan
# Purpose: Run jamf recon if org printer portal is reachable

PRINTER_PORTAL="https://cloud.com"

# Get the HTTP status code
STATUS_CODE=$(curl -k --silent --max-time 2 --output /dev/null --write-out "%{http_code}" "$PRINTER_PORTAL")

if [[ "$STATUS_CODE" == "200" ]]; then
    echo "✅ Printer portal reachable. Running policy."
    jamf policy -event instppm
else
    echo "⚠️ Printer portal Not reachable & Not in org network."
    exit 1
fi
