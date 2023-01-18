#!/bin/bash

#Schma source from apple https://swscan.apple.com/content/catalogs/others/index-rosettaupdateauto-1.sucatalog.gz
Buildversion=$(sw_vers -BuildVersion | awk -F. '{print $1}')
echo MAC OS Build Version :$Buildversion

rm -rf /private/var/tmp/rosettaupdateauto*

xmlLocationtemp="/private/var/tmp/rosettaupdateauto.gz"
downloadthexmlfile=$(curl --silent "https://swscan.apple.com/content/catalogs/others/index-rosettaupdateauto-1.sucatalog.gz">> $xmlLocationtemp )
gunzip $xmlLocationtemp
MACADMINS_URL="/private/var/tmp/rosettaupdateauto"
mv "$MACADMINS_URL" "$MACADMINS_URL.xml"
MACADMINS_URL1="/private/var/tmp/rosettaupdateauto.xml"
url=$(xmllint --xpath '//key[text()="ExtendedMetaInfo"]/following-sibling::dict/string[2][text() ="'${Buildversion}'"]/../../array/dict/string[contains(., "pkg")]/text()' "$MACADMINS_URL1")
    echo "URL : ${url}"

# Create temporary working directory
    tempDirectory=/Users/Shared
    rosettapkg=$(/usr/bin/curl --location --silent "$url" -o "$tempDirectory/RosettaUpdateAuto.pkg")

    /usr/sbin/installer -pkg "$tempDirectory/RosettaUpdateAuto.pkg" -target /
        if [[ $? == 0 ]]; then
            echo "Rosetta Successfully installed"         
            else
            echo "Unable to install Rosetta"
            exitCode=1
        fi
    # Remove the temporary working directory when done
    /bin/rm -Rf "$tempDirectory/RosettaUpdateAuto.pkg"
    /bin/rm -rf /private/var/tmp/rosettaupdateauto*
    exit $exitcode 
