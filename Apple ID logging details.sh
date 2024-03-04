#!/bin/bash
sudo -u $(stat -f "%Su" /dev/console) /bin/sh <<'END'
​
#set variables for Apple ID account and existence check
AppleID=`defaults read MobileMeAccounts Accounts | grep "AccountID" | sed 's/        AccountID = "//' | sed 's/";//'`
AccountExists=`echo "$AppleID" | grep "@"`
ManagedCheck=`defaults read MobileMeAccounts Accounts | grep "isManagedAppleID" | sed 's/        isManagedAppleID = //' | sed 's/;//'`
​
#check if account exists and display associated email address and account type
if [ -z "$AccountExists" ]
    then 
        echo "No Apple ID found"
    else
        if [ "$ManagedCheck" == 0 ]
            then
                echo "Personal Apple ID"
                echo "$AppleID"
            else
                echo "Managed Apple ID"
                echo "$AppleID"
        fi
