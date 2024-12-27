#!/bin/bash

#########################################################################################################
#                                                                                                       #
#                                  Microsoft Script Disclaimer                                          #
#                                                                                                       #
# This script is provided "AS IS" without warranty of any kind. Microsoft disclaims all implied         #
# warranties, including, without limitation, any implied warranties of merchantability or fitness       #
# for a particular purpose. The entire risk arising out of the use or performance of this script        #
# and associated documentation remains with you. In no event shall Microsoft, its authors, or any       #
# contributors be liable for any damages whatsoever (including, but not limited to, damages for         #
# loss of business profits, business interruption, loss of business information, or other pecuniary     #
# loss) arising out of the use of or inability to use this script or documentation, even if             #
# Microsoft has been advised of the possibility of such damages.                                        #
#                                                                                                       #
# Feedback: neiljohn@microsoft.com                                                                      #
#                                                                                                       #
#########################################################################################################

# Script: intuneMigration.sh
# -------------------------------------------------------------------------------------------------------
# Description:
# This script removes the Jamf framework from a Mac and prepares the device for migration to Microsoft 
# Intune. It prompts the user to start the migration process, removes the Jamf framework, installs the 
# Microsoft Intune Company Portal app (if needed), checks if the device is ADE-enrolled, and renews 
# profiles as necessary.
# -------------------------------------------------------------------------------------------------------
# Dependencies:
# - ADE: Device must be assigned to Intune before beginning the migration process
# - This script just handles the removal of Jamf and either starting setup assistant or Company Portal
#   for the user to complete migration. The onboarding process should be configured in Intune separately.
#########################################################################################################


# Function to check if the device is managed by Jamf
check_if_managed() {
  if profiles -P | grep -q "com.jamfsoftware"; then
    echo "Device is managed by Jamf."
  else
    echo "Device is not managed by Jamf. Exiting script."
    exit 0
  fi
}

# Function to check and install swiftDialog if not present
install_swiftDialog() {
  if [ ! -f "/usr/local/bin/dialog" ]; then
    echo "swiftDialog not found. Installing swiftDialog..."
    curl -L -o /tmp/dialog.pkg "https://github.com/swiftDialog/swiftDialog/releases/download/v2.5.2/dialog-2.5.2-4777.pkg"
    sudo installer -pkg /tmp/dialog.pkg -target /
    rm /tmp/dialog.pkg
    echo "swiftDialog installed successfully."
  else
    echo "swiftDialog is already installed."
  fi
}

# Function to display message to sign in to Company Portal
cp_sign_in_message() {
  /usr/local/bin/dialog \
    --bannertitle "Action Required: Sign in to Company Portal" \
    --message "To complete your device setup, you must sign in to the Company Portal app using your **Entra (Microsoft)** credentials.\n\nFailure to sign in to Company Portal will result in the loss of access to corporate resources such as **e-Mail** and **other essential services**.\n\nWhen you close this dialog, Company Portal will be open your screen, click **Sign-in** and complete the process to avoid service disruptions." \
    --button1text "Got it" \
    --blurscreen \
    --bannerimage colour=blue \
    --titlefont shadow=1 \
    --width 750 \
    --height 450 \
    --icon /Applications/Company\ Portal.app/Contents/Resources/AppIcon.icns
}

# Function to display "Waiting for Intune" message with spinner
waiting_for_intune() {
  /usr/local/bin/dialog \
    --bannertitle "Status: Waiting for Intune" \
    --message "Your device setup is in progress.\n\nWe're currently waiting for Intune to complete the necessary setup. This may take a few minutes.\n\nPlease keep this window open until setup is complete." \
    --blurscreen \
    --bannerimage colour=blue \
    --titlefont shadow=1 \
    --progress \
    --width 750 \
    --height 450 \
    --icon /Applications/Company\ Portal.app/Contents/Resources/AppIcon.icns \
    --no-buttons
    --progress &
  
  # Capture the dialog process ID to close it later if needed
  DIALOG_PID=$!
}

# Function to display message for ADE enrollment
ade_enrollment_message() {
  /usr/local/bin/dialog \
    --bannertitle "Action Required: Complete Device Enrollment" \
    --message "Your device is **ADE-enrolled** and requires additional setup to complete enrollment into **Intune**.\n\nPlease follow the setup assistant screens to sign in with your **Entra (Microsoft)** credentials. This process is necessary to gain access to corporate resources, including **e-Mail** and other essential services.\n\nWhen you close this dialog, the setup assistant will open. Follow the prompts to complete the enrollment process." \
    --button1text "Got it" \
    --blurscreen \
    --bannerimage colour=blue \
    --titlefont shadow=1 \
    --width 750 \
    --height 450 \
    --icon /Applications/Company\ Portal.app/Contents/Resources/AppIcon.icns
}

# Function to prompt the user to start the migration
prompt_migration() {

  # Display the dialog with improved message text
  /usr/local/bin/dialog \
    --bannertitle "Prepare for Device Migration" \
    --message "Your device is scheduled to be migrated from **Jamf** to **Microsoft Intune**.\n\nThis process will take approximately **20 minutes**, during which you will **not be able to use your Mac**." \
    --button1text "Migrate" \
    --button2text "Exit" \
    --blurscreen \
    --bannerimage colour=blue \
    --titlefont shadow=1 \
    --width 750 \
    --height 450 \
    --icon /Applications/Company\ Portal.app/Contents/Resources/AppIcon.icns

  # Check which button was clicked based on the exit code
  if [[ "$?" -eq 0 ]]; then
    echo "User is ready to start the migration."
    return 0  # Proceed with migration
  else
    echo "User chose not to migrate at this time."\
    exit 1  # Exit the script
  fi
}

# Function to start the migration dialog in progress mode
start_progress_dialog() {
  COMMAND_FILE="/tmp/dialog_command"
  echo "Initializing migration..." > "$COMMAND_FILE"
  
  /usr/local/bin/dialog \
    --bannertitle "Device Migration in Progress" \
    --icon /Applications/Company\ Portal.app/Contents/Resources/AppIcon.icns \
    --bannerimage colour=blue \
    --titlefont shadow=1 \
    --message "Your device is being migrated from Jamf to Microsoft Intune. Please do not power off or disconnect your device during this process." \
    --blurscreen \
    --force \
    --no-buttons \
    --progress \
    --width 750 \
    --height 450 \
    --commandfile "$COMMAND_FILE" &
  
  DIALOG_PID=$!
}

# Function to update the dialog progress bar and text via the command file
update_progress() {
  local progress_value="$1"
  local progress_text="$2"
  
  # Write the progress value and text separately to the command file
  echo "progress: $progress_value" > "$COMMAND_FILE"
  echo "progresstext: $progress_text" >> "$COMMAND_FILE"
  
  # Add a small delay to ensure swiftDialog processes each update properly
  sleep 1
}

# Function to completely remove Jamf framework
remove_jamf_framework() {
  update_progress 50 "Removing Jamf framework..."
  if command -v jamf >/dev/null 2>&1; then
    sudo jamf removeFramework
    if [ $? -eq 0 ]; then
      echo "Jamf framework removed from the Mac."
    else
      echo "Failed to remove Jamf framework."
    fi
  else
    echo "Jamf binary not found; it may have already been removed."
  fi
}

# Function to check if the device is ADE enrolled
check_ade_enrollment() {
  echo "Checking if the device is ADE enrolled..."

  # Run profiles status to check for DEP enrollment
  ade_status=$(profiles status -type enrollment 2>/dev/null | grep -i "Enrolled via DEP: Yes")

  if [ -n "$ade_status" ]; then
    echo "Device is ADE enrolled."
    ADE_ENROLLED=true
  else
    echo "Device is not ADE enrolled."
    ADE_ENROLLED=false
  fi
}

# Function to check and install the Intune Company Portal app if not present
check_and_install_company_portal() {
  if [ ! -d "/Applications/Company Portal.app" ]; then
    echo "Checking and installing Company Portal if required..."
    update_progress 100 "Installing Microsoft Intune Company Portal"
    echo "Company Portal app not found. Installing Company Portal..."
    curl -L -o /tmp/CompanyPortal.pkg "https://go.microsoft.com/fwlink/?linkid=853070"
    sudo installer -pkg /tmp/CompanyPortal.pkg -target /
    rm /tmp/CompanyPortal.pkg
    echo "Company Portal installed successfully."
  else
    echo "Company Portal app is already installed."
  fi
}

launch_company_portal() {
  # Open the Company Portal app
  open -a "Company Portal"
  
  # Bring Company Portal to the front
  osascript <<EOF
    tell application "Company Portal" to activate
EOF
}

# Function to renew profiles if the device is ADE enrolled
renew_profiles() {
  sudo profiles renew -type enrollment
  echo "Profiles renewed."
}

############################################################
##
## Main Script Execution Begins Here
##
#########################################

# Flag to track ADE enrollment
ADE_ENROLLED=false

# Check if the device is managed
check_if_managed

# Install swiftDialog if needed
install_swiftDialog

#Launch initial migration prompt
prompt_migration

#Launch actual migration dialog
start_progress_dialog

# Call the function to check and install Company Portal if needed
check_and_install_company_portal

# Check ADE enrollment before unmanaging the device
check_ade_enrollment

#unmanage_device "$computer_id" "$auth_token"
remove_jamf_framework

update_progress 90 "Device removed from Jamf, now starting Intune Migration"
sleep 2

# Close Dialog and any remaining jamf processes
killall Dialog
killall jamf

# If the device was ADE enrolled, renew profiles
if [ "$ADE_ENROLLED" = true ]; then

    # Show end user dialog about ADE enrollment process
    ade_enrollment_message

    # Renew profiles to trigger Intune setup
    renew_profiles

    # Show waiting for Intune dialog, this will remain open until Intune setup is complete and the onboarding script runs
    sleep 5
    waiting_for_intune
else

    # Show sign-in message for Company Portal
    cp_sign_in_message

    # Launch Company Portal
    launch_company_portal
fi


# Kill any remaining Dialog processes
killall Dialog
