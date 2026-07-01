#!/bin/bash
#
# Author: Manikandan
# Description: This script sets Google as the default search provider for Microsoft Edge.
#              It writes managed preferences to the system-level Edge plist.
#              Intended for use on macOS systems — requires sudo/root.
#              Equivalent to deploying com.assaabloy.edge.google configuration profile.
#
# 🔧 Scope: System (requires root)
# 📋 Keys set: DefaultSearchProviderEnabled, DefaultSearchProviderName,
#              DefaultSearchProviderKeyword, DefaultSearchProviderSearchURL

EDGE_PLIST="$HOME/Library/Preferences/com.microsoft.Edge"

echo "Configuring Microsoft Edge default search provider..."

# Enable the default search provider
defaults write "$EDGE_PLIST" DefaultSearchProviderEnabled -bool true

# Set provider name
defaults write "$EDGE_PLIST" DefaultSearchProviderName -string "Google"

# Set keyword
defaults write "$EDGE_PLIST" DefaultSearchProviderKeyword -string "google.com"

# Set search URL (using Edge/Chrome-style {searchTerms} placeholder)
defaults write "$EDGE_PLIST" DefaultSearchProviderSearchURL -string "https://www.google.com/search?q={searchTerms}"

sleep 2

# Set correct ownership and permissions so Edge can read it
chmod 644 "${EDGE_PLIST}.plist"
chown root:wheel "${EDGE_PLIST}.plist"

echo "Done. Edge default search provider set to Google."