#!/bin/bash

# Define variables
ADDIN_URL="https://yoururl here/:u:/r/sites/SoftwarePackageLibrary/Package%20For%20UAT/Onit%20Word%20add-in/manifest.xml"
ADDIN_XML="manifest.xml"
WORD_ADDIN_DIR="$HOME/Library/Containers/com.microsoft.Word/Data/Documents/wef"
XML_CONTENT='<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<OfficeApp xmlns="http://schemas.microsoft.com/office/appforoffice/1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:bt="http://schemas.microsoft.com/office/officeappbasictypes/1.0" xmlns:ov="http://schemas.microsoft.com/office/taskpaneappversionoverrides" xsi:type="TaskPaneApp">
  <Id>341a5c51-51c0-4c56-8dd9-b4c28c8699a8</Id>
  <Version>1.0.0.2</Version>
  <ProviderName>Onit</ProviderName>
  <DefaultLocale>en-US</DefaultLocale>
  -------------------------------------------
-----your xml code here ----------------------
--------------------------------------------
      </bt:LongStrings>
    </Resources>
  </VersionOverrides>
</OfficeApp>'

# Step 1: Create the wef directory if it doesn't exist
echo "Checking for the WEF directory..."
if [ ! -d "$WORD_ADDIN_DIR" ]; then
    echo "WEF directory does not exist. Creating it with 755 permissions..."
    mkdir -p "$WORD_ADDIN_DIR"
    chmod 755 "$WORD_ADDIN_DIR"
    if [ $? -eq 0 ]; then
        echo "Directory created and permissions set successfully."
    else
        echo "Failed to create directory or set permissions. Exiting."
        exit 1
    fi
else
    echo "WEF directory already exists."
fi

# Step 2: Attempt to download the manifest.xml file
echo "Downloading the manifest.xml file from SharePoint..."
curl -L -o "$WORD_ADDIN_DIR/$ADDIN_XML" "$ADDIN_URL"

# Check if the file exists and is not empty
if [ -s "$WORD_ADDIN_DIR/$ADDIN_XML" ]; then
    echo "Download completed successfully."
else
    echo "Download failed or file is empty. Creating XML file with provided content..."
    echo "$XML_CONTENT" > "$WORD_ADDIN_DIR/$ADDIN_XML"
    if [ $? -eq 0 ]; then
        echo "XML file created successfully."
    else
        echo "Failed to create XML file. Exiting."
        exit 1
    fi
fi

# Step 3: Set permissions on the manifest.xml file
chmod 755 "$WORD_ADDIN_DIR/$ADDIN_XML"
if [ $? -eq 0 ]; then
    echo "Permissions set on manifest.xml successfully."
else
    echo "Failed to set permissions on manifest.xml. Exiting."
    exit 1
fi

# Step 4: Open Microsoft Word and attempt to start the add-in
echo "Opening Microsoft Word to kickstart the add-in..."
open -a "Microsoft Word"

echo "Add-in setup completed. You may need to manually enable the add-in within Word if not done automatically."

# End of script
