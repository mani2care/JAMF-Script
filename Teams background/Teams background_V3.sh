#!/bin/zsh
set -euo pipefail

# Author: Manikandan (mani2care)
# Script Title: Microsoft Teams Background Setup (Batch Mode)
# Synopsis:
#   Finds your five " Teams background office space” images (any extension),
#   resizes each to exactly 1920×1080 px JPEG, writes it into Teams’ Uploads
#   folder with GUID suffixes 1111–5555, generates 280×158 px JPEG thumbnails,
#   and logs each step.

# 1) Get current console user
currentUser=$(/usr/bin/stat -f "%Su" /dev/console)

# 2) Ensure Teams is installed
if [[ ! -d "/Applications/Microsoft Teams.app" ]]; then
  echo "Microsoft Teams is not installed. Exiting..."
  # exit 1
fi

# 3) Define Teams Uploads folder
userHome=$(dscl . -read /Users/"$currentUser" NFSHomeDirectory | awk '{print $2}')
outputPath="$userHome/Library/Containers/com.microsoft.teams2/Data/Library/Application Support/Microsoft/MSTeams/Backgrounds/Uploads"
mkdir -p "$outputPath"

#clean the folder.
rm -rf "$outputPath/"*

# 4) Base GUID for all images
baseGUID="93E4CE45-EC48-4E25-B77B-8BB9EBC6"

# 5) Source directory (contains many images)
srcDir="/Users/Shared/Branding"

# 6) Find all image files (png/jpg/jpeg)
images=("$srcDir"/*.{png,jpg,jpeg,JPG,JPEG,PNG}(.N))

if [[ ${#images[@]} -eq 0 ]]; then
    echo "No images found in $srcDir"
    exit 0
fi

echo "Found ${#images[@]} images to process..."

# 7) Loop through all images
counter=1000   # start suffix numbering from 1000
for srcImage in "${images[@]}"; do
    ((counter++))                         # increment suffix
    suffix=$(printf "%04d" $counter)      # e.g., 1001, 1002, 1003...
    GUID="${baseGUID}${suffix}"

    destImage="$outputPath/${GUID}.jpeg"
    destThumb="$outputPath/${GUID}_thumb.jpeg"

    echo "Processing: $srcImage → $GUID"

    # Resize & move
    sips -z 1080 1920 "$srcImage" --out "$destImage" >/dev/null
    sips -z 158 280 "$destImage" --out "$destThumb" >/dev/null

    # Fix ownership
    chown "$currentUser":wheel "$destImage" "$destThumb"

    if [[ -f "$destImage" && -f "$destThumb" ]]; then
        #echo "✅ Added: $GUID"
    else
        echo "❌ Failed: $GUID"
    fi
done

# 8) Show final contents
echo "----------------------------------"
echo "Final contents of Teams Uploads:"
ls -1 "$outputPath"
