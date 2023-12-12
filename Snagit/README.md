check the application version and check as per your requirement app version name Snagit 2023 or Snagit 2024

Open the Composer.

Add the app to the Application folder.

Drag and drop it into Composer.

Change the application permissions to Owner = root and Group = wheel, mode 775. Apply permissions to Snagit 2023 and all enclosed items.

Change the LicenseKey file permissions to Owner = root and Group = wheel, mode 777. Apply permissions to Snagit 2023 and all enclosed items (if you prefer to add the key file manually).

If you'd like to add the theme file, drop it into the location "/Users/Shared/ABB.snagtheme." Using the post-install script, the "/Users/Shared/ABB.snagtheme" will be moved to "/Users/$loggedInUser/Library/Group\ Containers/7TQL462TU8.com.techsmith.snagit/Snagit\ 2024/Themes."

If you prefer to add the key file manually, use the script to create the key file and add it to Composer, or use another way. The post-install script has an option to add your key; it will create the key from the location "/Users/Shared/TechSmith/Snagit/LicenseKey." [Link](https://github.com/mani2care/JAMF-Script/new/main/Snagit#:~:text=Snagit-,Key,-Activation.sh)

Copy and paste the post-install script. [Link](https://github.com/mani2care/JAMF-Script/new/main/Snagit#:~:text=Snagit-,Postinstall,-.sh)

Copy and paste the pre-install script. [Link](https://github.com/mani2care/JAMF-Script/new/main/Snagit#:~:text=Snagit-,Preinstall,-.sh)

Package and test the function. Test, test, test!

Check the other settings and modifications for the app. Default Settings for Snagit

I have created the configuration profile as well to grant some permissions. Check the same. [Link](https://github.com/mani2care/JAMF-Script/blob/main/Snagit/Snagit.mobileconfig#:~:text=TechSmith%2D2023.2.2.sh-,Snagit,-.mobileconfig)https://github.com/mani2care/JAMF-Script/blob/main/Snagit/Snagit.mobileconfig#:~:text=TechSmith%2D2023.2.2.sh-,Snagit,-.mobileconfig

if you like to uninstall the snagit use this uninstaller script [link](https://github.com/mani2care/JAMF-Script/blob/main/Snagit/Snagit.mobileconfig#:~:text=Snagit.mobileconfig-,Snagit_Uninstaller,-.sh)https://github.com/mani2care/JAMF-Script/blob/main/Snagit/Snagit.mobileconfig#:~:text=Snagit.mobileconfig-,Snagit_Uninstaller,-.sh
