#!/bin/bash

# Assign the certificate name to the variable
MyCertificate="$4"

# Validate if MyCertificate is empty
if [ -z "$MyCertificate" ]; then
    echo "Step 1: Error - No certificate name provided. Exiting."
    exit 1
fi

echo "Step 1: Keychain Certificate \"$MyCertificate\" will be removed from all user keychains (if found)."
echo "Step 1.1: Private key for \"$MyCertificate\" will also be searched and deleted if found."

# Get a list of all user accounts with UID >= 500
echo "Step 2: Retrieving list of users with UID >= 500."
users=$(dscl . -list /Users UniqueID | awk '$2 >= 500 { print $1 }')

# Iterate over each user
for user in $users; do
    # Get the user's home directory (NFSHomeDirectory)
    home_dir=$(dscl . -read /Users/$user NFSHomeDirectory | awk '{print $2}')
    
    echo "Step 3: Checking keychains and identities for user: $user (Home Directory: $home_dir)"

    # Check if the home directory exists
    if [ -d "$home_dir" ]; then
        # Path to user's keychains
        keychains_dir="$home_dir/Library/Keychains"
        
        # Find all keychains in the user's directory
        echo "Step 4: Searching for keychains in $keychains_dir for user: $user."
        keychains=$(find "$keychains_dir" -name "*.keychain-db" 2>/dev/null)

        if [ -z "$keychains" ]; then
            echo "Step 5: No keychains found for user: $user in $keychains_dir."
        else
            # Iterate through each keychain
            for keychain in $keychains; do
                echo "Step 5: Checking keychain: $keychain for certificate \"$MyCertificate\"."

                # Find certificates matching the provided name in the current keychain
                hashes=$(sudo -u $user security find-certificate -c "$MyCertificate" -a -Z "$keychain" 2>/dev/null | grep SHA-1 | awk '{ print $NF }')

                # Check if any hashes were found
                if [ -n "$hashes" ]; then
                    echo "Step 6: Certificate \"$MyCertificate\" found in $keychain. Deleting it now."
                    # Delete the certificate if found
                    for hash in $hashes; do
                        echo "Step 7: Deleting certificate with hash: $hash from keychain: $keychain."
                        sudo -u $user security delete-certificate -Z $hash "$keychain"
                    done
                    echo "Step 8: Certificate \"$MyCertificate\" removed from keychain: $keychain."
                else
                    echo "Step 6: No certificate \"$MyCertificate\" found in $keychain."
                fi
            done
        fi

        # Find and delete private key (identity) associated with the certificate
        echo "Step 9: Searching for private key (identity) related to \"$MyCertificate\" for user: $user."
        identities=$(sudo -u $user security find-identity -v | grep "$MyCertificate")

        if [ -n "$identities" ]; then
            echo "Step 10: Private key (identity) for \"$MyCertificate\" found. Deleting now."
            sudo -u $user security delete-identity -c "$MyCertificate"
            echo "Step 11: Private key (identity) for \"$MyCertificate\" deleted."
        else
            echo "Step 10: No private key (identity) found for \"$MyCertificate\"."
        fi
    else
        echo "Step 3: Home directory for user $user not found or does not exist."
    fi
done

echo "Step 12: Keychain Certificate \"$MyCertificate\" and private key removal process completed for all users."
exit 0
