#!/bin/sh

# template script for running a command as root/admin

# variable and function declarations

# get the currently logged in user
currentUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }')

# global check if there is a user logged in
if [ -z "$currentUser" -o "$currentUser" = "loginwindow" ]; then
  echo "no user logged in, cannot proceed"
  exit 1
fi
# now we know a user is logged in

# convenience function to run a command as root/admin
# usage:
#   runAsRoot command arguments...
runAsRoot() {
  sudo "$@"
}

# main code starts here

# open a website in the root/admin user's default browser
runAsRoot profiles -R -p ec807626-7d6f-11e9-bc5b-2a86e4085a59
