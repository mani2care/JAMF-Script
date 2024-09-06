#!/bin/bash

# Define variables
ADDIN_URL="https://yoururlhere.com/:u:/r/sites/SoftwarePackageLibrary/Package%20For%20UAT/Onit%20Word%20add-in/manifest.xml"
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

# Step 0.1: Delete the existing manifest.xml file if it exists
delete_manifest_file() {
    # Step 1: Delete the existing manifest.xml file if it exists
    if [ -f "$WORD_ADDIN_DIR" ]; then
        echo "Deleting existing manifest.xml file..."
        rm -rf "$WORD_ADDIN_DIR"
    else
        echo "No existing manifest.xml file found."
    fi
}

# Call the function
delete_manifest_file

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

curl -s -L -o "$WORD_ADDIN_DIR/$ADDIN_XML" "$ADDIN_URL"

# Check if the download was successful, the file is not empty, or if it contains "403 FORBIDDEN"
if [ $? -ne 0 ] || [ ! -s "$WORD_ADDIN_DIR/$ADDIN_XML" ] || grep -q "403 FORBIDDEN" "$WORD_ADDIN_DIR/$ADDIN_XML"; then
    echo "Error: Download failed, the file is invalid, or 403 Forbidden detected. Creating XML file with provided content..."
    echo "$XML_CONTENT" > "$WORD_ADDIN_DIR/$ADDIN_XML"
    if [ $? -eq 0 ]; then
        echo "XML file created successfully."
    else
        echo "Failed to create XML file. Exiting."
        exit 1
    fi
else
    echo "Download completed successfully."
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

echo "Add-in setup completed. You may need to manually open the add-in within Word is not done automatically."

# End of script
