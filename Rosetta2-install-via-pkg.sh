#!/bin/bash

# Installs Rosetta will attempt to download the pkg from apple server and install it.
# Created By : Manikandan @mani2care
# On : 18-Jan-2023

exitcode=0

# Determine OS version
# Save current IFS state

OLDIFS=$IFS

IFS='.' read osvers_major osvers_minor osvers_dot_version <<< "$(/usr/bin/sw_vers -productVersion)"

# restore IFS to previous state

IFS=$OLDIFS

# Check to see if the Mac is reporting itself as running macOS 11

if [[ ${osvers_major} -ge 11 ]]; then

  # Check to see if the Mac needs Rosetta installed by testing the processor

  processor=$(/usr/sbin/sysctl -n machdep.cpu.brand_string | grep -o "Intel")
  
  if [[ -n "$processor" ]]; then
    echo "$processor processor installed. No need to install Rosetta."
  else

    # Check for Rosetta "oahd" process. If not found,
    # perform a non-interactive install of Rosetta.
    
    if /usr/bin/pgrep oahd >/dev/null 2>&1; then
        echo "Rosetta is already installed and running. Nothing to do."
    else

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

    fi
    fi
  else
    echo "Mac is running macOS $osvers_major.$osvers_minor.$osvers_dot_version."
    echo "No need to install Rosetta on this version of macOS."
fi

exit $exitcode
