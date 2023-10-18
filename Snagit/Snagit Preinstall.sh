#!/bin/sh

echo "Deleting previous Snagit installs (if present)..."
/usr/bin/find "/Applications" -name "Snagit*.app" -type d -maxdepth 1 -exec rm -rfv {} \;

rm -rf "/Users/Shared/TechSmith"
rm -rf "/Applications/Snagit 2023.app"
rm -rf "/Applications/Snagit 2022.app"
rm -rf "/Applications/Snagit 2021.app"

regkey="your key go's here "

if [ -n "$regkey" ]; then
  [[ ! -d "/Users/Shared/TechSmith/Snagit" ]] && /bin/mkdir -p "/Users/Shared/TechSmith/Snagit"
  /bin/echo "$regkey" > "/Users/Shared/TechSmith/Snagit/LicenseKey"
  /bin/chmod -R 777 "/Users/Shared/Snagit"
  /bin/chmod a+x "/Users/Shared/TechSmith/Snagit/LicenseKey"
fi

exit 0		## Success
exit 1		## Failure
