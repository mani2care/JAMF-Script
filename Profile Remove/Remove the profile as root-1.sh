#!/bin/sh

# template script for running a command as user

# variable and function declarations

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# get the currently logged in user
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )

# get the current user's UID
uid=$(id -u "$currentUser")


# test if root
if [[ $uid -ne 0 ]]; then
    >&2 echo "script requires super user privileges, exiting..."
    exit 1
fi

# continue with important things here
echo "I am root"

sudo profiles -R -p ec807626-7d6f-11e9-bc5b-2a86e4085a59
