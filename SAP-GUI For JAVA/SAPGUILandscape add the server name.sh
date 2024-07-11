#!/bin/sh

# Created by : manikandan @mani2care 11-Jul-2024 
# Description:
# This script creates an SAPGUI Landscape XML configuration file for the currently logged-in user on a Mac.
# It places the XML file in the user's Library/Preferences/SAP directory and sets the appropriate permissions.

# Get the current user logged in on the Mac
logged_in_user=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ {print $3}')

# Check if the logged-in user was detected
if [ -z "$logged_in_user" ]; then
  echo "No user currently logged in. Exiting script."
  exit 1
else
  echo "Logged-in user detected: $logged_in_user"
fi

#Remove the existing SAPGUILandscape.xml files 
#rm -rf /Users/manikandan/Library/Preferences/SAP/SAPGUILandscape.xml

## This variable defines the place where the xml will go. Change "filename.xml" to the correct name for the file
path_for_xml="/Users/${logged_in_user}/Library/Preferences/SAP/SAPGUILandscape.xml"

# Create the directory if it doesn't exist
mkdir -p "/Users/${logged_in_user}/Library/Preferences/SAP"

## Create the XML. You will need to copy/paste the unaltered XML file contents over the < all xml data goes here > section
cat << EOXML > "${path_for_xml}"
<?xml version="1.0" encoding="UTF-8"?>
<Landscape updated="2024-07-11T13:53:44Z" version="1" origin="file:/Users/$logged_in_user/Library/Preferences/SAP/SAPGUILandscape.xml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" generator="SAP GUI for Java 7.70 rev 5" xsi:noNamespaceSchemaLocation="SAPUILandscape.xsd">
  <Services>
    <Service name="SAP BI Development AWD" expert="1" msid="" uuid="12386728-51a6-43c1-bfad-4927d6ed5f51" type="SAPGUI" server="it-s-srvgen3.it.abb.com:3200" mode="1"/>
    <Service name="SAP BI Production AWP" expert="1" msid="" uuid="f73f16af-4133-4f9f-b06a-1163f77b6f2d" type="SAPGUI" server="it-s-sapawp1.it.abb.com:3202" mode="1"/>
    <Service name="SAP ERP Development AED" expert="1" msid="" uuid="059a094f-644d-4328-afd6-f924fc6ba385" type="SAPGUI" server="it-s-srvgen3.it.abb.com:3202" mode="1"/>
    <Service name="SAP ERP Integration AEI" expert="1" msid="" uuid="8ffd1e73-ac48-4bd6-94b7-1edd3b2cee7d" type="SAPGUI" server="it-s-srvgen3.it.abb.com:3203" mode="1"/>
    <Service name="SAP ERP Production AEP" expert="1" msid="" uuid="4862980e-7a07-4da6-8d65-4a493bbc7c57" type="SAPGUI" server="it-v-sapaepe.it.abb.com:3200" mode="1"/>
  </Services>
  <Workspaces default="7e86fda7-43f3-4b6c-ac62-0d87cf77b3d6">
    <Workspace expanded="1" name="JavaGUI Services" uuid="7e86fda7-43f3-4b6c-ac62-0d87cf77b3d6" description="JavaGUI Services configuration">
      <Item uuid="8656aa9a-430e-435c-83c9-22cf5cf9c650" serviceid="4862980e-7a07-4da6-8d65-4a493bbc7c57"/>
      <Item uuid="e81b3187-74b6-45b2-a271-aa4603742a7f" serviceid="8ffd1e73-ac48-4bd6-94b7-1edd3b2cee7d"/>
      <Item uuid="73957911-400c-42d3-9031-2969628bf47d" serviceid="059a094f-644d-4328-afd6-f924fc6ba385"/>
      <Item uuid="1ae51a32-a394-4289-a3be-9e3724c11fa5" serviceid="f73f16af-4133-4f9f-b06a-1163f77b6f2d"/>
      <Item uuid="c34f83f8-39ac-4d1b-a8c5-621fe8389e0e" serviceid="12386728-51a6-43c1-bfad-4927d6ed5f51"/>
    </Workspace>
  </Workspaces>
  <Messageservers/>
  <Routers/>
</Landscape>
EOXML

# Set ownership and permissions for the XML file
echo "Setting ownership and permissions for: $path_for_xml"

## Make adjustments to the ownership and permissions here, otherwise the logged in user may not be able to read the file contents
/usr/sbin/chown $logged_in_user "$path_for_xml"
/bin/chmod 755 "$path_for_xml"

# Provide feedback on completion
if [ $? -eq 0 ]; then
  echo "SAPGUI Landscape XML file created and permissions set successfully."
else
  echo "Failed to create SAPGUI Landscape XML file or set permissions."
fi
