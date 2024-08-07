#!/bin/bash

# Title:	Get Screen Saver and Wallpaper Information
# Version:	2023.12.26
# Author:	https://github.com/itjimbo

loggedInUser=$(/usr/bin/stat -f%Su /dev/console)

wallpaper_store_path="/Users/${loggedInUser}/Library/Application Support/com.apple.wallpaper/Store/Index.plist"

getScreensaverBase64=$(plutil -extract AllSpacesAndDisplays xml1 -o - "${wallpaper_store_path}" | awk '/<data>/,/<\/data>/' | xargs | tr -d " " | tr "<" "\n" | tail -2 | head -1 | cut -c6-)
echo "screenSaverBase64: ${getScreensaverBase64}"

getWallpaperBase64=$(plutil -extract AllSpacesAndDisplays xml1 -o - "${wallpaper_store_path}" | awk '/<data>/,/<\/data>/' | xargs | tr -d " " | tr "<" "\n" | head -2 | tail -1 | cut -c6-)
echo "wallpaperBase64: ${getWallpaperBase64}"

getWallpaperLocation=$(plutil -extract AllSpacesAndDisplays xml1 -o - "${wallpaper_store_path}" | grep -A 2 "relative" | head -2 | tail -1 | xargs | cut -c9- | rev | cut -c10- | rev)
echo "wallpaperLocation: ${getWallpaperLocation}"