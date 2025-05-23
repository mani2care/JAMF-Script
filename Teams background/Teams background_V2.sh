#!/bin/zsh

# Author: Manikandan (mani2care)
# Script Title: Microsoft Teams Background Setup
# Script Synopsis: This script sets up a custom background for Microsoft Teams, downloading the background image if not present, 
# and placing it in the appropriate Teams background upload folder. It includes options to clean and replace existing images 
# based on a specified GUID or to generate a new one.

# Define the static GUID for the background file
STATIC_GUID="F0397AC7-A070-4F74-AD2C-AB4C5D962EF9"  # Leave empty to generate a new GUID

# Define the download URL if image is not present
BACKGROUND_URL="https://www.google.com/url?sa=i&url=https%3A%2F%2Fwww.jamf.com%2Fblog%2Fpowerautomate-flow-jamf-pro-microsoft-teams%2F&psig=AOvVaw0rxMK5sddnxUZjRgwuAWxp&ust=1744740351544000&source=images&cd=vfe&opi=89978449&ved=0CBQQjRxqFwoTCPiArMKO2IwDFQAAAAAdAAAAABAJ"
Orgname="org"

# Define the input image path
imagePath="/Users/Shared/${Orgname}_Teams_Background.png"

# Get current user
currentUser=$(/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }')
userHome=$(dscl . -read /Users/"$currentUser" NFSHomeDirectory | awk '{print $2}')


# Check if Microsoft Teams is installed
if [[ ! -d "/Applications/Microsoft Teams.app" ]]; then
    echo "❌ Microsoft Teams is not installed. Exiting..."
    exit 1
fi

# Define Teams Upload path
outputPath="$userHome/Library/Containers/com.microsoft.teams2/Data/Library/Application Support/Microsoft/MSTeams/Backgrounds/Uploads"

# Create output directory if it doesn't exist
[[ ! -d "$outputPath" ]] && mkdir -p "$outputPath"

# If STATIC_GUID is empty, generate a new GUID
if [[ -z "$STATIC_GUID" ]]; then
    STATIC_GUID=$(uuidgen)
    echo "🆕 Generated new GUID: $STATIC_GUID"
fi

# Define static output filenames
outputFile="$outputPath/$STATIC_GUID.png"
thumbName="${STATIC_GUID}_thumb.png"
thumbPath="$outputPath/$thumbName"

# Check if the static GUID-named file already exists
if [[ -f "$outputFile" ]]; then
    echo "⚠️ Background image with GUID $STATIC_GUID already exists. Exiting to avoid overwrite."
    exit 0
fi

# If image is not present locally, download it
if [[ ! -f "$imagePath" ]]; then
    echo "⬇️ Image not found at $imagePath, attempting download..."
    curl -v -f -s -o "$imagePath" "$BACKGROUND_URL" >/dev/null 2>&1

    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to download background image. Exiting..."
        exit 1
    fi

    # Validate the file is a PNG
    fileType=$(file -b --mime-type "$imagePath")
    if [[ "$fileType" != "image/png" ]]; then
        echo "❌ Downloaded file is not a valid PNG image. Exiting..."
        rm -f "$imagePath"
        exit 1
    fi

    echo "✅ Image downloaded and validated successfully."
fi

# Process the image to create the Teams background
echo "🛠️ Creating Background from image..."
sips -z 1080 1920 "$imagePath" --out "$outputFile" >/dev/null 2>&1

# Create thumbnail
echo "🛠️ Creating Background Thumbnail..."
sips -z 158 220 "$outputFile" --out "$thumbPath" >/dev/null 2>&1

# Set ownership
chown "$currentUser":wheel "$outputFile"
chown "$currentUser":wheel "$thumbPath"

echo "🎉 Background and thumbnail successfully created:"
echo "$outputFile"
