#!/bin/zsh

# Author: Manikandan (mani2care)
# Script Title: Microsoft Teams Background Setup (Batch Mode)
# Synopsis:
#   Finds your five " Teams background office space” images (any extension),
#   resizes each to exactly 1920×1080 px JPEG, writes it into Teams’ Uploads
#   folder with GUID suffixes 1111–5555, generates 280×158 px JPEG thumbnails,
#   and logs each step.

set -euo pipefail

# 1) Get the current console user
currentUser=$(/usr/bin/stat -f "%Su" /dev/console)

# 2) Ensure Teams is installed
if [[ ! -d "/Applications/Microsoft Teams.app" ]]; then
  echo "Microsoft Teams is not installed. Exiting..."
  exit 1
fi

# 3) Define the real Teams Uploads folder
userHome=$(dscl . -read /Users/"$currentUser" NFSHomeDirectory | awk '{print $2}')
outputPath="$userHome/Library/Containers/com.microsoft.teams2/Data/Library/Application Support/Microsoft/MSTeams/Backgrounds/Uploads"
mkdir -p "$outputPath"

# 4) Prepare GUID base and suffixes
baseGUID="93E4CE45-EC48-4E25-B77B-8BB9EBC6"
suffixList=(1111 2222 3333 4444 5555)

# 5) Source directory for your five images
srcDir="/Users/Shared/Branding"

for idx in {1..5}; do
  GUID="${baseGUID}${suffixList[$idx]}"

  # 5a) Locate the image
  matches=("$srcDir/Teams background office space - $idx".*)
  if [[ ! -f "${matches[1]}" ]]; then
    echo "Source image #$idx not found, skipping."
    continue
  fi

  srcImage="${matches[1]}"
  echo "Found source image #$idx: ${srcImage}"

  destImage="$outputPath/${GUID}.jpeg"
  destThumb="$outputPath/${GUID}_thumb.jpeg"

  # 5b) Resize and move
  sips -z 1080 1920 "$srcImage" --out "$destImage" >/dev/null
  sips -z 158 280 "$destImage" --out "$destThumb" >/dev/null

  # 5c) Fix ownership
  chown "$currentUser":wheel "$destImage" "$destThumb"

  # 5d) Confirm success
  if [[ -f "$destImage" && -f "$destThumb" ]]; then
    echo "Successfully moved and set permissions for GUID $GUID"
    echo ""
  else
    echo "Failed to move or set permissions for GUID $GUID"
  fi

done

# 6) Show final contents
echo "Final contents of Teams Uploads folder:" ls -1 "$outputPath"
