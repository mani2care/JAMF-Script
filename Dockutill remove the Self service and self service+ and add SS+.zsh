#!/bin/zsh --no-rcs
# --------------------------------------------------------------------
# remove_selfservice_dock.zsh
#
# Purpose : Detect how many "Self Service" / "Self Service+" icons
#           exist in the current console user's Dock, remove ALL
#           of them, then re-check to confirm nothing remains.
#
# Notes   : - Requires dockutil (path auto-detected below).
#           - Must be run as root (e.g. via Jamf policy) since it
#             uses launchctl asuser + sudo -u to act in the GUI
#             user's context.
#           - Matching is done CASE-INSENSITIVE / SUBSTRING against
#             the label column of `dockutil --list`, so it will
#             catch things like "Self Service", "Self Service+",
#             "Self Service +", trailing spaces, etc.
#           - If an item is pushed via a Configuration Profile
#             (custom Dock payload), dockutil cannot permanently
#             remove it -- it will just reappear after the profile
#             re-applies. The script will tell you if that's likely.
# --------------------------------------------------------------------

emulate -L zsh
setopt pipefail

##### Config #####################################################
LOG_PREFIX="[SS-Dock-Cleanup]"
MATCH_PATTERN="self service"   # case-insensitive substring to hunt for
####################################################################

log() { echo "${LOG_PREFIX} $*" }

# --- Resolve dockutil binary --------------------------------------
DOCKUTIL_BIN=""
for candidate in /usr/local/bin/dockutil /opt/homebrew/bin/dockutil; do
    if [[ -x "$candidate" ]]; then
        DOCKUTIL_BIN="$candidate"
        break
    fi
done
if [[ -z "$DOCKUTIL_BIN" ]] && command -v dockutil >/dev/null 2>&1; then
    DOCKUTIL_BIN=$(command -v dockutil)
fi
if [[ -z "$DOCKUTIL_BIN" ]]; then
    log "ERROR: dockutil not found. Install it first (e.g. via Jamf/Munki)."
    exit 1
fi
log "Using dockutil at: $DOCKUTIL_BIN"

# --- Resolve currently logged in console user ----------------------
loggedInUser=$(stat -f%Su /dev/console)
if [[ -z "$loggedInUser" || "$loggedInUser" == "root" || "$loggedInUser" == "loginwindow" ]]; then
    log "ERROR: No valid GUI user logged in at console. Exiting."
    exit 1
fi
uid=$(id -u "$loggedInUser")
log "Target user: $loggedInUser (uid $uid)"

# --- Helper: run a dockutil command as the logged in user ----------
run_as_user() {
    launchctl asuser "$uid" sudo -u "$loggedInUser" "$DOCKUTIL_BIN" "$@"
}

# --- Helper: get raw dock list (label<TAB>path<TAB>type<TAB>...) ---
get_dock_list() {
    run_as_user --list 2>/dev/null
}

# --- Helper: print only the label column, trimmed ------------------
matching_labels() {
    get_dock_list | awk -F'\t' '{print $1}' | \
        sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | \
        grep -i -- "$MATCH_PATTERN"
}

# --- STEP 1: Initial scan ------------------------------------------
log "Scanning Dock for entries matching '${MATCH_PATTERN}'..."
log "Raw dockutil --list output for reference:"
get_dock_list | while IFS= read -r line; do log "    RAW: $line"; done

initialMatches="$(matching_labels)"
initialCount=0
if [[ -n "$initialMatches" ]]; then
    initialCount=$(print -r -- "$initialMatches" | grep -c .)
fi

if [[ "$initialCount" -eq 0 ]]; then
    log "No entries matching '${MATCH_PATTERN}' found in Dock. Nothing to do."
    exit 0
fi

log "Found $initialCount matching item(s):"
print -r -- "$initialMatches" | while IFS= read -r label; do
    log "  - '$label'"
done

# --- STEP 2: Remove all matches -------------------------------------
removedCount=0
failedCount=0
maxAttempts=20   # safety guard against infinite loops

attempt=0
while true; do
    attempt=$((attempt + 1))
    if (( attempt > maxAttempts )); then
        log "WARNING: Hit max removal attempts ($maxAttempts). Stopping loop."
        break
    fi

    currentMatches="$(matching_labels)"
    if [[ -z "$currentMatches" ]]; then
        break
    fi

    # Take the first remaining match and try to remove it
    label="$(print -r -- "$currentMatches" | head -n1)"
    log "Removing '$label'..."

    if run_as_user --remove "$label" --no-restart 2>/tmp/dockutil_err.$$; then
        removedCount=$((removedCount + 1))
        log "  Removed '$label'."
        rm -f /tmp/dockutil_err.$$
    else
        errMsg=$(cat /tmp/dockutil_err.$$ 2>/dev/null)
        rm -f /tmp/dockutil_err.$$
        failedCount=$((failedCount + 1))
        log "  WARNING: Failed to remove '$label'. dockutil said: ${errMsg:-<no output>}"
        log "  This likely means it's enforced by a Configuration Profile. Stopping loop."
        break
    fi
done

# --- STEP 3: Relaunch Dock once, after all removals ------------------
log "Relaunching Dock for user $loggedInUser..."

run_as_user --add "/Applications/Self Service+.app" --position beginning --no-restart

launchctl asuser "$uid" sudo -u "$loggedInUser" killall Dock 2>/dev/null || true
sleep 2

# --- STEP 4: Re-check for any remaining entries -----------------------
log "Re-scanning Dock to confirm removal..."
finalMatches="$(matching_labels)"
finalCount=0
if [[ -n "$finalMatches" ]]; then
    finalCount=$(print -r -- "$finalMatches" | grep -c .)
fi

if [[ "$finalCount" -eq 0 ]]; then
    log "SUCCESS: No entries matching '${MATCH_PATTERN}' remain in the Dock."
    log "Summary: initial=$initialCount removed=$removedCount failed=$failedCount final=0"
    exit 0
else
    log "NOTICE: $finalCount item(s) still present after removal attempt:"
    print -r -- "$finalMatches" | while IFS= read -r label; do
        log "  - '$label'"
    done
    log "This usually means the item is enforced by a Configuration Profile"
    log "(custom Dock payload) rather than a plain user Dock preference."
    log "Remove/adjust that profile in Jamf Pro, then re-run this script."
    log "Summary: initial=$initialCount removed=$removedCount failed=$failedCount final=$finalCount"
    exit 2
fi
