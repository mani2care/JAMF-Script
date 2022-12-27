#!/bin/bash

# File: Get-Office-Last-Version.sh
# File Created: 2020-07-17 10:35:40
# File Re-Created: 2022-12-25

# Usage : Install Office365 applications in the last version available on macadmins site.

#Note : Via jamf In policy mention the parameter values any one value in below.
# Word
# Excel
# Powerpoint
# Onedrive
# Onenote
# Outlook
# MAU
# MSTeamsAudiodriver
# MSTeams
# FullOfficesuite365businesspro
# FullOfficesuite365

# Example : ./Get-Office-Last-Version.sh MAU
# Example : ./Get-Office-Last-Version.sh MAU MSTeamsAudiodriver

# Author: @mani2care

#XML location : https://macadmins.software/latest.xml
#Script location :https://github.com/bpstuder/macos_scripts_public/blob/main/Policies/Get-Office-Last-Version.sh

function install_software () {
    SOFTWARE_ID=$1
    SOFTWARE_NAME=$2
echo
echo "Injected Microsoft office is ${1} ${2} "

            if [[ "$2" == "MSTeamsAudiodriver" ]]; then
                URL=$(echo "${LATEST_XML}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/moreurl/text()' -)
                SHA256=""
            else
                URL=$(echo "${LATEST_XML}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/download/text()' -)
                SHA256=$(echo "${LATEST_XML}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/sha256/text()' -)
            fi
    #URL=$(echo "${LATEST_XML}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/download/text()' -)
    VERSION=$(echo "${LATEST_XML}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/cfbundleshortversionstring/text()' -)
    #SHA256=$(echo "${LATEST_XML}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/sha256/text()' -)
    title=$(echo "${LATEST_XML}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/title/text()' -)
    subtext=$(echo "${LATEST_XML}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/subtext/text()' -)
    publishedon=$(echo "${LATEST_XML}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/lastupdated/text()' -)
    minos=$(echo "${LATEST_XML}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/min_os/text()' -)
    macho=$(echo "${LATEST_XML}" | xmllint --xpath '//latest/package[id="'${SOFTWARE_ID}'"]/mach-o/text()' -)

    echo
    echo "Title             : ${title}"
    echo "URL               : ${URL}"
    echo "Version           : ${VERSION}"
    echo "App-subtext       : ${subtext}"
    echo "SHA256            : ${SHA256}"
    echo "Publishedon       : ${publishedon}"
    echo "OSsupportfrom     : ${minos}"
    echo "Hardwaresupport   : ${macho}"
    echo

function Officedownload(){
                    # download the installer package and capture the % percentage sign progress for Dialog display
                    echo "Attempting to download the package ${title}"
                    /usr/bin/curl --retry 3 --retry-delay 5 -L "${URL}" -# -o "${title}.pkg" 2>&1 | while IFS= read -r -n1 -d '' char; do
                      [[ $char =~ [0-9] ]] && keep=1 ;
                      [[ $char == % ]] && echo "Progress: Downloading version(${VERSION}) : ${progress}%" && progress="" && keep=0 ;
                      [[ $keep == 1 ]] && progress="$progress$char" ;
                    done
}
cd ${TEMP_PATH}
Officedownload
            echo $?
            if [[ $? == 0 ]]; then
                echo "Downloaded the package ${title}"
            else
                echo "[ERROR] Curl command failed with: $curlResult"
            fi
    echo
    echo "Verifying Checksum for the package ${title}"
    CHECKSUM=$(shasum -a 256 "${title}.pkg" | awk -F" " '{print $1}')

                # install the package if checksum validates
                if [ "$SHA256" = "$CHECKSUM" ] || [ "$SHA256" = "" ]; then
                    echo "Checksum verified. Installing package ${title}.pkg"
                    /usr/sbin/installer -pkg "${title}.pkg" -target /
                       if [[ $? == 0 ]]; then
                        echo "${title} Successfully installed"
                    else
                        echo "[ERROR] Unable to install ${title}"
                        exit 1
                    fi

                else
                    echo "Checksum failed. Recalculate the SHA 256 checksum and try again. Or download may not be valid."
                    exit 1
                fi

                # remove the temporary working directory when done
                rm -Rf "$TEMP_PATH"
                echo "Deleting working directory '$TEMP_PATH'"

                exit 0

                }

## Variables
MACADMINS_URL="https://macadmins.software/latest.xml"
TEMP_PATH="/tmp/apps"

# Main

if [[ -d "${TEMP_PATH}" ]]; then
    rm -rf ${TEMP_PATH}
    echo ${TEMP_PATH}
fi
echo "Creating working directory ${TEMP_PATH}"
mkdir ${TEMP_PATH}

LATEST_XML=$(curl -H "Accept: text/xml" -sfk ${MACADMINS_URL})

LATEST_VERSION=$(echo "${LATEST_XML}" | xmllint --xpath "//latest/vl2019/text()" -)
echo
echo "Office Suite Installer version : ${LATEST_VERSION}"

for param in "$@"; do
    case $param in 
        Word)
            install_software "com.microsoft.word.standalone.365" "Word"
            ;;
        Excel)
            install_software "com.microsoft.excel.standalone.365" "Excel"
            ;;
        Powerpoint)
            install_software "com.microsoft.powerpoint.standalone.365" "Powerpoint"
            ;;
        Onedrive)
            install_software "com.microsoft.onedrive.standalone" "OneDrive"
            ;;
        Onenote)
            install_software "com.microsoft.onenote.standalone.365" "OneNote"
            ;;
        Outlook)
            install_software "com.microsoft.outlook.standalone.365" "Outlook"
            ;;
        MAU)
            install_software "com.microsoft.autoupdate.standalone" "MAU"
            ;;
        MSTeamsAudiodriver)
            install_software "com.microsoft.teams.standalone" "MSTeamsAudiodriver"
            ;;
        MSTeams)
            install_software "com.microsoft.teams.standalone" "MSTeams"
            ;;
        FullOfficesuite365businesspro)
            install_software "com.microsoft.office.suite.365.businesspro" "FullOfficesuite365businesspro"
            ;;
        FullOfficesuite365)
            install_software "com.microsoft.office.suite.365" "FullOfficesuite365"
            ;;
        *)
            echo "Unknown Parameter"
    esac
done
echo "Unknown Parameter hence unable to process further"
exitCode=1
exit $exitCode
