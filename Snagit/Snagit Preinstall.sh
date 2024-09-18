#!/bin/sh

snagit_versions=("2023" "2022" "2024")

for version in "${snagit_versions[@]}"; do
    # Get the process IDs of the application
    app_pids=($(pgrep -f "/Applications/Snagit $version"))

    # Check if there are any running processes
    if [ ${#app_pids[@]} -gt 0 ]; then
        # Terminate all running processes forcefully
        for pid in "${app_pids[@]}"; do
            kill -9 "$pid"
            echo "The application Snagit $version has been forcefully terminated with PID=$pid"
        done
    fi

    # Remove the installation directory
    echo "Deleting Snagit $version installation (if present)..."
    find "/Applications" -name "Snagit $version*.app" -type d -maxdepth 1 -exec rm -rfv {} \;

    # Remove other related files and directories
    rm -rf "/Users/Shared/TechSmith"
    rm -rf "/Users/Shared/ABB.snagtheme"
    rm -rf ~/Library/Preferences/com.TechSmith.Snagit${version}*
    rm -rf ~/Library/Preferences/com.techsmith.snagit.capturehelper${version}*
    rm -rf ~/Library/Preferences/com.TechSmith.SupportSnagit*
    rm -rf ~/Library/Group\ Containers/7TQL462TU8.com.techsmith.snagit/Snagit\ $version/Themes/ABB.snagtheme

done

exit 0  ## Success
exit 1  ## Failure
