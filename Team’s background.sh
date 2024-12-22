#!/bin/sh

# teamsbackground.sh
#
# Author: Tobias Almén
#
# Version: 1.0
#
# This script downloads an image, resizes it, and sets it as a custom background image for Microsoft Teams (work or school).
#
# Usage:
# ./teamsbackground.sh
#
# Details:
# The script uses the `sips` command, a built-in utility on macOS for image processing, and `curl` for downloading the image.
# It sets a custom background image for Microsoft Teams by placing the image in the appropriate directory.
#
# In this script:
# - TMPDIR=$(mktemp -d): This command creates a temporary directory.
# - BACKGROUND_URL: This is the URL of the image to download.
# - BACKGROUND_FOLDER: This is the directory where Microsoft Teams looks for custom background images.
# - curl -f -s -O "$BACKGROUND_URL": This command downloads the image.
# - process_image function: This function processes the image. It checks if the image is in the defined formats (png, jpg, jpeg), converts it to PNG if it's not, renames it to a generated UUID, copies it to the background folder, resizes it to a height of 186 pixels while maintaining the aspect ratio, and then crops it to have a width of 238 pixels.
# - The script also checks if it has been run before and if Microsoft Teams is installed. If the script has been run before, it exits. If Microsoft Teams is not installed, it prints an error message and exits.
# - If the image is a zip file, the script unzips it and processes the extracted files.
#
# Requirements:
# - Microsoft Teams must be installed and the user must have write access to the Microsoft Teams background images directory.

### Do not modify ###
CURRENT_USER=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
USER_HOME=$(dscl . -read /users/${CURRENT_USER} NFSHomeDirectory | cut -d " " -f 2)
TMPDIR=$(mktemp -d)
BACKGROUND_FOLDER="$USER_HOME/Library/Containers/com.microsoft.teams2/Data/Library/Application Support/Microsoft/MSTeams/Backgrounds/Uploads"

### Required settings ###
BACKGROUND_URL="" # Replace with the URL of the image or zip you want to download

### Optional settings ###
IMAGE_FORMATS=("png" "jpg" "jpeg") # Add or remove image formats as needed
RUN_CHECK=false # Set to true to prevent the script from running more than once
RUN_CHECK_FILENAME=".teamsbackground" # Name of the file to check if the script has been run before
RUN_CHECK_PATH="$USER_HOME/Library/Application Support/$RUN_CHECK_FILENAME" # Path to the file to check if the script has been run before

log_message() {
    echo "[$(date)] - $1"
}

process_image() {
    local f="$1"
    file_extension="${f##*.}"
    for format in "${IMAGE_FORMATS[@]}"; do
        if [[ "$file_extension" == "$format" ]]; then
            IMAGE_GUID=$(uuidgen)
            IMAGE_PATH="$BACKGROUND_FOLDER/$IMAGE_GUID.png"
            IMAGE_THUMB_PATH="$BACKGROUND_FOLDER/${IMAGE_GUID}_thumb.png"
            # If not a png, sips convert it to png in current folder  
            if [[ $f != *.png ]]; then
                sips -s format png "$f" -o "$f.png" > /dev/null
            fi

            # Rename the file to the GUID in current folder
            mv "$f" "$IMAGE_GUID"
            # Copy the image to the background folder
            cp "$IMAGE_GUID" "$IMAGE_PATH"
            # Copy the thumb file to the background folder
            cp "$IMAGE_GUID" "$IMAGE_THUMB_PATH"

            # Resize the image to have a height of 186, maintaining the aspect ratio
            sips -Z 186 "$IMAGE_THUMB_PATH" -o "$IMAGE_THUMB_PATH" > /dev/null 2>&1
            # Get the current width of the image
            width=$(sips -g pixelWidth "$IMAGE_THUMB_PATH" | awk '/pixelWidth:/{print $2}')
            # Calculate the amount to crop from the sides
            crop=$((($width - 238) / 2))
            # Crop the image to have a width of 238, centered
            sips -z 186 238 "$IMAGE_THUMB_PATH" -o "$IMAGE_THUMB_PATH" > /dev/null 2>&1

            log_message "Background image downloaded and set, image GUID: $IMAGE_GUID"
        fi
    done
}

# Check if script has been run before
if [ $RUN_CHECK == true ]; then
    if [ -f "$RUN_CHECK_PATH" ]; then
        log_message "Script has already been run, exiting"
        # Clean up
        rm -rf "$TMPDIR"
        
        exit 0
    else
        touch "$RUN_CHECK_PATH"
    fi
fi

# Check that Teams actually exists
if [ ! -d "/Applications/Microsoft Teams (work or school).app" ]; then
    log_message "Microsoft Teams is not installed"
    # Clean up
    rm -rf "$TMPDIR"

    exit 1
fi

# Check if folder exists
if [ ! -d "$BACKGROUND_FOLDER" ]; then
    mkdir "$BACKGROUND_FOLDER"
    log_message "Created Uploads folder"
fi

cd "$TMPDIR"

# Download image
curl -f -s -O "$BACKGROUND_URL"

if [ $? == 0 ]; then
    # Check if the image is a png
    for f in *; do
        # Check if the image is a zip file and extract it
        if [[ $f == *.zip ]]; then
            unzip -q "$f"
            # Process the extracted files
            for extracted in *; do
                process_image "$extracted"
            done
            continue
        fi
        # Process the image
        process_image "$f"
    done

    # Clean up
    rm -rf "$TMPDIR"

    exit 0

else
    log_message "Failed to download image"
    # Clean up
    rm -rf "$TMPDIR"

    exit 1
fi
