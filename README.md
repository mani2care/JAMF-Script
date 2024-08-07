How to set Screensaver for macOS Sonoma

**Thanks to itjimbo (https://github.com/itjimbo) and Howie Isaacks (http://www.linkedin.com/in/howieisaacks)**
1) Create a folder on your test Mac to place the custom screensaver image(ex:/Library/Screen Savers/Customname)

2) Set screensaver manually from system settings on the test Mac.

3) Run [Get Screen Saver and Wallpaper Information.bash](https://github.com/itjimbo/macOS-Screen-Saver-and-Wallpaper/blob/main/Get%20Screen%20Saver%20and%20Wallpaper%20Information.bash) script on the test Mac to get screenSaverBase64 value of the folder.

4) Create package to push the custom screensaver to all Mac.

5) Copy the screenSaverBase64 value and paste it to [Set Screen Saver and Keep User's Wallpaper.sh](https://github.com/itjimbo/macOS-Screen-Saver-and-Wallpaper/blob/main/Set%20Screen%20Saver%20and%20Keep%20User's%20Wallpaper.sh) script line 14

6) Create policy in Jamf then push the custom screensaver image package first the run Set Screen Saver and Keep User's Wallpaper.sh first then run [Set ScreenSaver for Sonoma Script 2.sh](https://github.com/macbudS/Apple_Mac_scripts/blob/main/Set%20Screensaver%20in%20Sonoma/Set%20ScreenSaver%20for%20Sonoma%20Script%202.sh)

Note:- 
1) Test the policy before move to production
2) No need to re-run the Get Screen Saver and Wallpaper Information.bash script when you want to change the screensaver image, just replace the image in the cutsomname(ex:/Library/Screen Savers/Customname) folder then re-run the Set Screen Saver and Keep User's Wallpaper.sh first then run Set ScreenSaver for Sonoma Script 2.sh
