#!/bin/zsh -e
 
#######################
#
# Script does the following:
#
# Checks if Computer already has a record in JAMF
# If record exists in JAMF it updates the Purchasing Account with the imagingDoneValue
# If record doesn't exist in JAMF it notes the error
# Exits with a success or failure message
#
# Intended to be run on a macOS machine as part of a zero-touch
#  imaging process.
#
##########################
#
#	Last Updated 2023-April-19 by John Bowman
#
########################

# Check to see if a value was passed in parameter 4 from Jamf.
if [ "$4" != "" ]
  then
    apiUsername=$4
  else
    echo "No Jamf API username supplied. Exiting."
    exit 1
fi

# Check to see if a value was passed in parameter 5 from Jamf.
if [ "$5" != "" ]
  then
    apiPassword=$5
  else
    echo "No Jamf API password supplied. Exiting."
    exit 1
fi


### Constants - Go ahead and edit these if you need ###
# JAMF API
jamfBaseURL="https://your.jamf.url"
# Other variables
imagingDoneValue="ImagingDone" # Exact value of string in JAMF pop-up for Extension attribute that tracks when it was last updated


### Global Variables ###
serialNumber=$(system_profiler SPHardwareDataType | grep Serial | awk '{print $NF}')
# echo "Found Computer Serial Number of $serialNumber"

computerID=""
purchasingStatus=""
bearerToken=""
tokenExpirationEpoch="0"


runScript () {
  getComputerID
  getJamfPurchasingStatus
  updateJamfImagingStatus
  invalidateToken
}

json_value() { # Version 2023.3.4-1 - Copyright (c) 2023 Pico Mitchell - MIT License - Full license and help info at https://randomapplications.com/json_value
	{ set -- "$(/usr/bin/osascript -l 'JavaScript' -e 'ObjC.import("unistd"); function run(argv) { const stdin = $.NSFileHandle.fileHandleWithStandardInput; let out; for (let i = 0;' \
		-e 'i < 3; i ++) { let json = (i === 0 ? argv[0] : (i === 1 ? argv[argv.length - 1] : ($.isatty(0) ? "" : $.NSString.alloc.initWithDataEncoding((stdin.respondsToSelector("re"' \
		-e '+ "adDataToEndOfFileAndReturnError:") ? stdin.readDataToEndOfFileAndReturnError(ObjC.wrap()) : stdin.readDataToEndOfFile), $.NSUTF8StringEncoding).js.replace(/\n$/, ""))))' \
		-e 'if ($.NSFileManager.defaultManager.fileExistsAtPath(json)) json = $.NSString.stringWithContentsOfFileEncodingError(json, $.NSUTF8StringEncoding, ObjC.wrap()).js; if (/[{[]/' \
		-e '.test(json)) try { out = JSON.parse(json); (i === 0 ? argv.shift() : (i === 1 && argv.pop())); break } catch (e) {} } if (out === undefined) throw "Failed to parse JSON."' \
		-e 'argv.forEach(key => { out = (Array.isArray(out) ? (/^-?\d+$/.test(key) ? (key = +key, out[key < 0 ? (out.length + key) : key]) : (key === "=" ? out.length : undefined)) :' \
		-e '(out instanceof Object ? out[key] : undefined)); if (out === undefined) throw "Failed to retrieve key/index: " + key }); return (out instanceof Object ? JSON.stringify(' \
		-e 'out, null, 2) : out) }' -- "$@" 2>&1 >&3)"; } 3>&1; [ "${1##* }" != '(-2700)' ] || { set -- "json_value ERROR${1#*Error}"; >&2 printf '%s\n' "${1% *}"; false; }
}

getBearerToken() {
	response=$(curl -s -u "$apiUsername":"$apiPassword" "$jamfBaseURL"/api/v1/auth/token -X POST)
	bearerToken=$(json_value "${response}" token)
	#bearerToken=$(echo "$response" | plutil -extract token raw -)
	tokenExpiration=$(json_value "${response}" expires | awk -F . '{print $1}')
	#tokenExpiration=$(echo "$response" | plutil -extract expires raw - | awk -F . '{print $1}')
	tokenExpirationEpoch=$(date -j -f "%Y-%m-%dT%T" "$tokenExpiration" +"%s")
}

checkTokenExpiration() {
    nowEpochUTC=$(date -j -f "%Y-%m-%dT%T" "$(date -u +"%Y-%m-%dT%T")" +"%s")
    if [[ tokenExpirationEpoch -gt nowEpochUTC ]]
    then
        echo "Token valid until the following epoch time: " "$tokenExpirationEpoch"
    else
        echo "No valid token available, getting new token"
        getBearerToken
    fi
}

invalidateToken() {
	responseCode=$(curl -w "%{http_code}" -H "Authorization: Bearer ${bearerToken}" $jamfBaseURL/api/v1/auth/invalidate-token -X POST -s -o /dev/null)
	if [[ ${responseCode} == 204 ]]
	then
		echo "Token successfully invalidated"
		bearerToken=""
		tokenExpirationEpoch="0"
	elif [[ ${responseCode} == 401 ]]
	then
		echo "Token already invalid"
	else
		echo "An unknown error occurred invalidating the token"
	fi
}



getComputerID () {
  local api_stylesheet=$(mktemp -t "getComputerID")
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
	<xsl:stylesheet version=\"1.0\" xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\">
	    <xsl:output method=\"text\"/>

	    <xsl:template match=\"/\">
	        <xsl:value-of select=\"/computers/computer/id\"/>
	    </xsl:template>

	</xsl:stylesheet>" > "$api_stylesheet"

    checkTokenExpiration
	computerID=$(curl -ks -H "Authorization: Bearer ${bearerToken}" $jamfBaseURL/JSSResource/computers/match/$serialNumber | xsltproc "$api_stylesheet" -)
	#rm -f "$api_stylesheet"
	if [ "$computerID" eq "" ]; then
    echo "Unable to locate a computer in JAMF with this serial number. How is this script even running?"
		exit 1
	fi
	echo "Found JAMF Computer ID of $computerID"	
}

getJamfPurchasingStatus () {
	checkTokenExpiration
	purchasingStatusRaw=$(curl -ks -H "Authorization: Bearer ${bearerToken}" "${jamfBaseURL}/api/v1/computers-inventory-detail/$computerID" )
	purchasingStatus=$(json_value "${purchasingStatusRaw}" purchasing)
}


updateJamfImagingStatus () {
	#Update JAMF Purchasing Account
	purchasingJSON="{\"purchasing\": {"
	purchasingJSON+="\"purchased\": $(json_value "${purchasingStatus}" purchased),"
	purchasingJSON+="\"leased\": $(json_value "${purchasingStatus}" leased),"
	if [ "$(json_value "${purchasingStatus}" poNumber)" != "null"  ]; then
		purchasingJSON+="\"poNumber\": \"$(json_value "${purchasingStatus}" poNumber)\","
	fi
	if [ "$(json_value "${purchasingStatus}" lifeExpectancy)" != "null"  ]; then
		purchasingJSON+="\"lifeExpectancy\": $(json_value "${purchasingStatus}" lifeExpectancy),"
	fi
	if [ "$(json_value "${purchasingStatus}" purchasePrice)" != "null"  ]; then
		purchasingJSON+="\"purchasePrice\": \"$(json_value "${purchasingStatus}" purchasePrice)\","
	fi
	if [ "$(json_value "${purchasingStatus}" purchasingContact)" != "null"  ]; then
		purchasingJSON+="\"purchasingContact\": \"$(json_value "${purchasingStatus}" purchasingContact)\","
	fi
	if [ "$(json_value "${purchasingStatus}" appleCareId)" != "null"  ]; then
		purchasingJSON+="\"appleCareId\": \"$(json_value "${purchasingStatus}" appleCareId)\","
	fi
	if [ "$(json_value "${purchasingStatus}" vendor)" != "null"  ]; then
		purchasingJSON+="\"vendor\": \"$(json_value "${purchasingStatus}" vendor)\","
	fi
	if [ "$(json_value "${purchasingStatus}" leaseDate)" != "null"  ]; then
		purchasingJSON+="\"leaseDate\": \"$(json_value "${purchasingStatus}" leaseDate)\","
	fi
	if [ "$(json_value "${purchasingStatus}" poDate)" != "null"  ]; then
		purchasingJSON+="\"poDate\": \"$(json_value "${purchasingStatus}" poDate)\","
	fi
	if [ "$(json_value "${purchasingStatus}" warrantyDate)" != "null"  ]; then
		purchasingJSON+="\"warrantyDate\": \"$(json_value "${purchasingStatus}" warrantyDate)\","
	fi
	purchasingJSON+="\"purchasingAccount\": \"${imagingDoneValue}\""
	purchasingJSON+="}}"


	checkTokenExpiration
	 curl -X PATCH "${jamfBaseURL}/api/v1/computers-inventory-detail/$computerID" \
	 	-H "Authorization: Bearer ${bearerToken}" \
	 	-H "Content-Type: application/json" -d "${purchasingJSON}" > /dev/null

	echo "Computer $computerID updated to indicate imaging done."	

}

runScript
#echo $purchasingStatus
#echo $purchasingJSON
exit 0
