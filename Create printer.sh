#!/bin/zsh
#
# LPadmin printer setup
#
# $4 - Printer Name (human visible)
# $5 - IP / DNS address
# $6 - PPD file to use
# $7 - Sharable (Yes/No)
# $8 - Printer DNS Queue Name

if [[ $8 != "" ]]; then
	echo "Creating IPP Printer"
    SEDstring=$(echo $4 | sed -e 's/ /_/g')
	/usr/sbin/lpadmin -p "$SEDstring" -L "$4" -E -o printer-is-shared=$7 -v ipp://$8/ipp -P "$6" -D "$4"
else
	echo "Creating Direct IP Printer"
	/usr/sbin/lpadmin -p "_$5" -L "$4" -E -o printer-is-shared=$7 -v lpd://$5 -P "$6" -D "$4"
fi
