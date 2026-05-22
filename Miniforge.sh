#!/bin/bash
#https://github.com/conda-forge/miniforge

logged_in_user=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ {print $3}')

CONDA_PATH="/Users/${logged_in_user}/conda"

# Create folder if missing
if [ ! -d "$CONDA_PATH" ]; then
    mkdir -p "$CONDA_PATH"
fi

# Install Miniforge
bash /private/tmp/Miniforge/Miniforge3-Darwin-arm64.sh -b -p "$CONDA_PATH"

rm -rf /private/tmp/Miniforge
