#!/usr/bin/env bash

#
DAYS_BEFORE_EXPIRE=14
SECONDS_BEFORE_EXPIRE=$((${DAYS_BEFORE_EXPIRE}*24*3600))
#
CERTIFICATE_CN="DeviceNetworkAccess-WiFi"
SYSTEM_KEYCHAIN_PATH=/Library/Keychains/System.keychain
#
WIFI_PROFILE_NAME="Corp-wifi"
#

function x_get_profile_id_by_name {

local PROFILE_ID=$(profiles show -o stdout-xml | xmllint --xpath "//key[.='ProfileDisplayName']/following-sibling::string[1][.='${WIFI_PROFILE_NAME}']/ancestor::dict[1]/key[.='ProfileIdentifier']/following-sibling::string[1]/text()" -)
echo ${PROFILE_ID}

}

function x_renew_profile {

local PROFILE_ID=$1
echo "profiles renew -identifier=${PROFILE_ID}"

}

function x_check_certificate_expired {

security find-certificate -c "${CERTIFICATE_CN}" -p | openssl x509 -noout -checkend ${SECONDS_BEFORE_EXPIRE} >/dev/null 2>/dev/null
return $?
}

# main starts here

if x_check_certificate_expired; then
  echo "Certificate ${CERTIFICATE_CN} is ACTIVE; Status: OK"
else
  echo "Certificate ${CERTIFICATE_CN} is READY to renew; Status: RENEW_READY"
  WIFI_PROFILE_ID=$(x_get_profile_id_by_name ${WIFI_PROFILE_NAME})
  x_renew_profile ${WIFI_PROFILE_ID}
fi
