#!/bin/zsh --no-rcs
##############################################################################
#
# Script Name      : Gimp_Photogimp_Installer.zsh
# Description      : Safely install for Intel and Apple Silicon Macs
#
# Author           : Manikandan R (https://github.com/mani2care)
# Team             : JAMF
#
# Version          : 1.0.0
# Created Date     : 2026-06-12
# Last Modified    : 2026-06-12
#
# Supported macOS  : macOS 13+
# Run As           : Root
#
# Change History
# ---------------------------------------------------------------------------
# Version | Date       | Author      | Changes
# ---------------------------------------------------------------------------
# 1.0.0   | 2026-06-12 | Manikandan  | Initial release
#
##############################################################################

###############################################################################
# GIMP + PhotoGIMP Installation Script
# Run as: root (via Jamf Pro policy)
#
# What this script does:
#   1. Detects if GIMP is installed and what version
#   2. Compares installed version against latest from gimp.org
#   3. If GIMP is missing or outdated — downloads and installs the latest DMG
#   4. Launches GIMP headlessly once so it creates its config directories
#   5. Downloads the latest PhotoGIMP release from GitHub
#   6. Backs up any existing GIMP config to /Users/Shared/GIMP_backup_<timestamp>
#   7. Removes any old PhotoGIMP version folder if present
#   8. Installs PhotoGIMP into ~/Library/Application Support/GIMP/
#   9. Sets correct ownership/permissions on the GIMP config directory
#  10. Validates everything is in place
#  11. Logs all activity to /private/var/log/gimp_photogimp_install.log
#
# Logs to: /private/var/log/gimp_photogimp_install.log
###############################################################################

###############################################################################
# Configuration
###############################################################################

LOG_FILE="/private/var/log/gimp_photogimp_install.log"
MAX_LOG_SIZE_KB=2048
WORK_DIR="/private/tmp/gimp_install_$$"

# Known versions — script will also try to detect latest dynamically
GIMP_KNOWN_LATEST="3.2.4"
PHOTOGIMP_KNOWN_VERSION="3.0"

# Download URLs
GIMP_MACOS_DOWNLOAD_ROOT="https://download.gimp.org/gimp"
PHOTOGIMP_API_URL="https://api.github.com/repos/Diolinux/PhotoGIMP/releases/latest"

# Install paths
GIMP_APP="/Applications/GIMP.app"
GIMP_BINARY="${GIMP_APP}/Contents/MacOS/gimp"

###############################################################################
# Detect Logged-in User
###############################################################################

CONSOLE_USER=$(stat -f "%Su" /dev/console)
CONSOLE_UID=$(id -u "$CONSOLE_USER" 2>/dev/null)
USER_HOME="/Users/${CONSOLE_USER}"
GIMP_CONFIG_DIR="${USER_HOME}/Library/Application Support/GIMP"
GIMP_SHARED_STAGING="/usr/local/share/gimp_photogimp_staging"

###############################################################################
# Logging
###############################################################################

log() {
    local MESSAGE="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | ${MESSAGE}" | tee -a "$LOG_FILE"
}

fail() {
    log "ERROR: $1"
    log "=================================================="
    log "GIMP / PhotoGIMP Installation FAILED"
    log "=================================================="
    cleanup_workdir
    exit 1
}

###############################################################################
# Log Rotation
###############################################################################

rotate_log() {
    if [[ -f "$LOG_FILE" ]]; then
        local SIZE_KB
        SIZE_KB=$(du -k "$LOG_FILE" | awk '{print $1}')
        if [[ "$SIZE_KB" -gt "$MAX_LOG_SIZE_KB" ]]; then
            mv "$LOG_FILE" "${LOG_FILE}.bak"
            touch "$LOG_FILE"
            chmod 644 "$LOG_FILE"
            log "Log rotated. Previous log saved to ${LOG_FILE}.bak"
        fi
    fi
}

###############################################################################
# Cleanup
###############################################################################

cleanup_workdir() {
    if [[ -d "$WORK_DIR" ]]; then
        rm -rf "$WORK_DIR"
        log "Cleaned up work directory: $WORK_DIR"
    fi
}

###############################################################################
# Pre-flight Checks
###############################################################################

check_root() {
    log "---------- Root Check ----------"
    if [[ "$(id -u)" -ne 0 ]]; then
        echo "ERROR: This script must be run as root."
        exit 1
    fi
    log "Running as root: OK"
}

check_console_user() {
    log "---------- Console User Check ----------"
    if [[ -z "$CONSOLE_USER" || "$CONSOLE_USER" == "root" ]]; then
        fail "No logged-in user found or user is root. A user must be logged in."
    fi
    log "Console user: $CONSOLE_USER (UID: $CONSOLE_UID)"
    log "User home: $USER_HOME"
}

detect_arch() {
    log "---------- Architecture Detection ----------"
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        GIMP_DMG_ARCH="arm64"
        log "Architecture: Apple Silicon (arm64)"
    else
        GIMP_DMG_ARCH="x86_64"
        log "Architecture: Intel (x86_64)"
    fi
}

check_network() {
    log "---------- Network Check ----------"
    if /usr/bin/curl -s --max-time 10 https://download.gimp.org -o /dev/null; then
        log "Network connectivity: OK"
    else
        fail "No network connectivity. Cannot reach download.gimp.org."
    fi
}

check_disk_space() {
    log "---------- Disk Space Check ----------"
    local AVAILABLE_GB
    AVAILABLE_GB=$(df -g / | awk 'NR==2 {print $4}')
    log "Available disk space: ${AVAILABLE_GB}GB (need ~1GB)"
    if [[ "$AVAILABLE_GB" -lt 1 ]]; then
        fail "Insufficient disk space. At least 1GB required."
    fi
    log "Disk space: OK"
}

###############################################################################
# Version Helpers
###############################################################################

version_gt() {
    # Returns 0 (true) if $1 > $2 using sort -V
    [[ "$(printf '%s\n' "$1" "$2" | sort -V | tail -1)" == "$1" && "$1" != "$2" ]]
}

###############################################################################
# Detect Installed GIMP Version
###############################################################################

get_installed_gimp_version() {
    INSTALLED_GIMP_VERSION=""

    if [[ ! -d "$GIMP_APP" ]]; then
        log "GIMP.app not found at ${GIMP_APP}."
        return 1
    fi

    # Try reading version from Info.plist
    local PLIST="${GIMP_APP}/Contents/Info.plist"
    if [[ -f "$PLIST" ]]; then
        INSTALLED_GIMP_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST" 2>/dev/null)
    fi

    if [[ -z "$INSTALLED_GIMP_VERSION" ]]; then
        # Fallback: try running the binary
        if [[ -x "$GIMP_BINARY" ]]; then
            INSTALLED_GIMP_VERSION=$("$GIMP_BINARY" --version 2>/dev/null | awk '{print $NF}')
        fi
    fi

    if [[ -n "$INSTALLED_GIMP_VERSION" ]]; then
        log "Installed GIMP version: ${INSTALLED_GIMP_VERSION}"
        return 0
    else
        log "GIMP.app found but could not determine version."
        return 1
    fi
}

###############################################################################
# Detect Latest GIMP Version from gimp.org
###############################################################################

get_latest_gimp_version() {
    log "Checking latest GIMP version from download.gimp.org..."

    # Step 1: Scrape the root index to find the highest stable vX.Y directory.
    # This adapts automatically to major version changes (v3.x → v4.x etc.)
    # without any hardcoded path.
    local ROOT_LISTING
    ROOT_LISTING=$(/usr/bin/curl -fsSL --max-time 15 "${GIMP_MACOS_DOWNLOAD_ROOT}/" 2>/dev/null)

    # Extract all vX.Y directory names, sort by version, pick the highest
    local LATEST_MAJOR_MINOR
    LATEST_MAJOR_MINOR=$(echo "$ROOT_LISTING" \
        | grep -oE 'v[0-9]+\.[0-9]+' \
        | sort -t. -k1,1V -k2,2n \
        | tail -1)

    if [[ -z "$LATEST_MAJOR_MINOR" ]]; then
        LATEST_MAJOR_MINOR="v$(echo "$GIMP_KNOWN_LATEST" | awk -F. '{print $1"."$2}')"
        log "WARNING: Could not detect latest GIMP major/minor from root index. Using: ${LATEST_MAJOR_MINOR}"
    else
        log "Latest GIMP major/minor on gimp.org: ${LATEST_MAJOR_MINOR}"
    fi

    GIMP_MACOS_DOWNLOAD_BASE="${GIMP_MACOS_DOWNLOAD_ROOT}/${LATEST_MAJOR_MINOR}/macos"
    log "GIMP macOS download base: ${GIMP_MACOS_DOWNLOAD_BASE}"

    # Step 2: Check the versioned macos/ directory for the LATEST-IS-x.x.x marker
    local LISTING
    LISTING=$(/usr/bin/curl -fsSL --max-time 15 "${GIMP_MACOS_DOWNLOAD_BASE}/" 2>/dev/null)

    LATEST_GIMP_VERSION=$(echo "$LISTING" \
        | grep -oE 'LATEST-IS-[0-9]+\.[0-9]+\.[0-9]+' \
        | head -1 \
        | sed 's/LATEST-IS-//')

    if [[ -z "$LATEST_GIMP_VERSION" ]]; then
        log "WARNING: Could not detect latest GIMP patch version. Falling back to known: ${GIMP_KNOWN_LATEST}"
        LATEST_GIMP_VERSION="$GIMP_KNOWN_LATEST"
    else
        log "Latest GIMP version on gimp.org: ${LATEST_GIMP_VERSION}"
    fi
}

###############################################################################
# Get Latest PhotoGIMP Version from GitHub API
###############################################################################

get_latest_photogimp_version() {
    log "Checking latest PhotoGIMP release from GitHub..."

    local API_RESPONSE
    API_RESPONSE=$(/usr/bin/curl -fsSL --max-time 15 \
        -H "Accept: application/vnd.github.v3+json" \
        "$PHOTOGIMP_API_URL" 2>/dev/null)

    LATEST_PHOTOGIMP_VERSION=$(echo "$API_RESPONSE" | /usr/bin/python3 -c \
        "import sys,json; d=json.load(sys.stdin); print(d.get('tag_name','').lstrip('v'))" 2>/dev/null)

    if [[ -z "$LATEST_PHOTOGIMP_VERSION" ]]; then
        log "WARNING: Could not detect latest PhotoGIMP version from GitHub API. Using known: ${PHOTOGIMP_KNOWN_VERSION}"
        LATEST_PHOTOGIMP_VERSION="$PHOTOGIMP_KNOWN_VERSION"
        # Fallback: construct URL from known version
        PHOTOGIMP_DOWNLOAD_URL="https://github.com/Diolinux/PhotoGIMP/releases/download/${LATEST_PHOTOGIMP_VERSION}/PhotoGIMP.zip"
    else
        log "Latest PhotoGIMP version on GitHub: ${LATEST_PHOTOGIMP_VERSION}"

        # Extract the macOS/generic zip asset URL directly from the API response.
        # This avoids hardcoding the filename — if the maintainer renames the asset
        # in a future release, we still get the right file.
        #
        # Selection priority:
        #   1. Exact match: PhotoGIMP.zip
        #   2. Any non-linux zip asset
        #   3. Fallback: constructed URL (last resort)
        PHOTOGIMP_DOWNLOAD_URL=$(echo "$API_RESPONSE" | /usr/bin/python3 -c "
import sys, json
d = json.load(sys.stdin)
assets = d.get('assets', [])
# All zip assets that are not Linux-specific
zips = [a['browser_download_url'] for a in assets
        if a['name'].lower().endswith('.zip')
        and 'linux' not in a['name'].lower()]
# Prefer exact historical name first
exact = [u for u in zips if u.lower().endswith('photogimp.zip')]
result = (exact or zips or [''])[0]
print(result)
" 2>/dev/null)

        if [[ -z "$PHOTOGIMP_DOWNLOAD_URL" ]]; then
            log "WARNING: Could not extract asset URL from API response. Falling back to constructed URL."
            PHOTOGIMP_DOWNLOAD_URL="https://github.com/Diolinux/PhotoGIMP/releases/download/${LATEST_PHOTOGIMP_VERSION}/PhotoGIMP.zip"
        fi
    fi

    log "PhotoGIMP download URL: ${PHOTOGIMP_DOWNLOAD_URL}"
}

###############################################################################
# GIMP Installation
###############################################################################

install_gimp() {
    log "---------- GIMP Installation ----------"

    local GIMP_VERSION_MAJOR
    GIMP_VERSION_MAJOR=$(echo "$LATEST_GIMP_VERSION" | awk -F. '{print $1"."$2}')
    local DMG_NAME="gimp-${LATEST_GIMP_VERSION}-${GIMP_DMG_ARCH}.dmg"
    local DMG_URL="${GIMP_MACOS_DOWNLOAD_BASE}/${DMG_NAME}"
    local DMG_PATH="${WORK_DIR}/${DMG_NAME}"

    log "Downloading GIMP ${LATEST_GIMP_VERSION} (${GIMP_DMG_ARCH})..."
    log "URL: ${DMG_URL}"

    /usr/bin/curl -fSL --max-time 600 --progress-bar \
        -o "$DMG_PATH" "$DMG_URL" >> "$LOG_FILE" 2>&1 \
        || fail "Failed to download GIMP DMG from ${DMG_URL}"

    log "Download complete: ${DMG_PATH}"
    log "Mounting DMG..."

    local MOUNT_OUTPUT
    MOUNT_OUTPUT=$(/usr/bin/hdiutil attach "$DMG_PATH" -nobrowse -readonly -noverify 2>&1)
    echo "$MOUNT_OUTPUT" >> "$LOG_FILE"

    # hdiutil output columns are tab-separated; the mount path (which may contain
    # spaces, e.g. "/Volumes/GIMP 3.2.4") is always the last tab-delimited field
    # on lines that contain /Volumes/. Using grep + cut on tabs is reliable here.
    local MOUNT_POINT
    MOUNT_POINT=$(echo "$MOUNT_OUTPUT" | grep -E $'\t/Volumes/' | tail -1 | cut -f3-)
    # Trim any leading/trailing whitespace
    MOUNT_POINT="${MOUNT_POINT#"${MOUNT_POINT%%[![:space:]]*}"}"
    MOUNT_POINT="${MOUNT_POINT%"${MOUNT_POINT##*[![:space:]]}"}"

    if [[ -z "$MOUNT_POINT" ]]; then
        fail "Could not determine DMG mount point."
    fi
    log "Mounted at: ${MOUNT_POINT}"

    # Find GIMP.app inside the DMG
    local SOURCE_APP
    SOURCE_APP=$(find "$MOUNT_POINT" -maxdepth 2 -name "GIMP.app" -type d | head -1)

    if [[ -z "$SOURCE_APP" ]]; then
        /usr/bin/hdiutil detach "$MOUNT_POINT" -force >> "$LOG_FILE" 2>&1
        fail "GIMP.app not found inside DMG at ${MOUNT_POINT}"
    fi
    log "Found app in DMG: ${SOURCE_APP}"

    # Remove existing GIMP.app if present
    if [[ -d "$GIMP_APP" ]]; then
        log "Removing existing GIMP.app before install..."
        rm -rf "$GIMP_APP" || fail "Could not remove existing ${GIMP_APP}"
        log "Existing GIMP.app removed."
    fi

    log "Copying GIMP.app to /Applications/..."
    /bin/cp -R "$SOURCE_APP" /Applications/ >> "$LOG_FILE" 2>&1 \
        || fail "Failed to copy GIMP.app to /Applications/"

    log "Detaching DMG..."
    /usr/bin/hdiutil detach "$MOUNT_POINT" -force >> "$LOG_FILE" 2>&1

    # Fix ownership
    /usr/sbin/chown -R root:wheel "$GIMP_APP" >> "$LOG_FILE" 2>&1
    log "Ownership set: root:wheel on ${GIMP_APP}"

    # Validate install
    if [[ -d "$GIMP_APP" ]]; then
        local NEW_VERSION
        NEW_VERSION=$(/usr/libexec/PlistBuddy -c \
            "Print :CFBundleShortVersionString" \
            "${GIMP_APP}/Contents/Info.plist" 2>/dev/null)
        log "GIMP installed successfully. Version: ${NEW_VERSION}"
    else
        fail "GIMP.app not found after install."
    fi
}

###############################################################################
# Launch GIMP once headlessly to create config directories
#
# PhotoGIMP requires ~/.../GIMP/3.0/ to already exist.
# The official instructions say "Open GIMP once, then close it."
# We launch it as the console user with a 20s timeout then kill it.
###############################################################################

initialize_gimp_config() {
    log "---------- Initializing GIMP Config Directories ----------"

    local EXPECTED_CONFIG="${GIMP_CONFIG_DIR}/${LATEST_PHOTOGIMP_VERSION}"

    if [[ -d "$EXPECTED_CONFIG" ]]; then
        log "GIMP config directory already exists: ${EXPECTED_CONFIG}"
        return 0
    fi

    log "Launching GIMP as ${CONSOLE_USER} to create config dirs (20s timeout)..."

    /bin/launchctl asuser "$CONSOLE_UID" \
        /usr/bin/su - "$CONSOLE_USER" -c \
        "open -a '${GIMP_APP}' && sleep 20 && osascript -e 'quit app \"GIMP\"'" \
        >> "$LOG_FILE" 2>&1 &

    local LAUNCH_PID=$!
    sleep 25

    # Kill GIMP process if still running
    /usr/bin/pkill -u "$CONSOLE_USER" -x "gimp" >> "$LOG_FILE" 2>&1 || true
    /usr/bin/pkill -u "$CONSOLE_USER" -x "GIMP" >> "$LOG_FILE" 2>&1 || true
    wait $LAUNCH_PID 2>/dev/null || true

    # Give filesystem a moment
    sleep 2

    if [[ -d "$EXPECTED_CONFIG" ]]; then
        log "GIMP config directory created: ${EXPECTED_CONFIG}"
    else
        # Create it manually if GIMP didn't make it (headless launch can fail in some MDM environments)
        log "Config dir not created by GIMP launch. Creating manually..."
        /bin/launchctl asuser "$CONSOLE_UID" \
            /usr/bin/su - "$CONSOLE_USER" -c \
            "mkdir -p '${GIMP_CONFIG_DIR}/${LATEST_PHOTOGIMP_VERSION}'" \
            >> "$LOG_FILE" 2>&1 \
            || fail "Could not create GIMP config directory."
        log "Config directory created manually: ${GIMP_CONFIG_DIR}/${LATEST_PHOTOGIMP_VERSION}"
    fi
}

###############################################################################
# Backup Existing GIMP Config
###############################################################################

backup_gimp_config() {
    log "---------- Backing Up Existing GIMP Config ----------"

    if [[ ! -d "$GIMP_CONFIG_DIR" ]]; then
        log "No existing GIMP config to back up. Skipping."
        return 0
    fi

    local TIMESTAMP
    TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
    local BACKUP_DIR="/Users/Shared/GIMP_backup_${TIMESTAMP}"

    log "Backing up ${GIMP_CONFIG_DIR} → ${BACKUP_DIR}"
    /bin/cp -R "$GIMP_CONFIG_DIR" "$BACKUP_DIR" >> "$LOG_FILE" 2>&1 \
        || fail "Failed to create backup at ${BACKUP_DIR}"

    # Ensure the console user can access the backup
    /usr/sbin/chown -R "${CONSOLE_USER}:staff" "$BACKUP_DIR" >> "$LOG_FILE" 2>&1
    chmod -R 755 "$BACKUP_DIR" >> "$LOG_FILE" 2>&1

    log "Backup created: ${BACKUP_DIR}"
    GIMP_BACKUP_PATH="$BACKUP_DIR"
}

###############################################################################
# Detect Installed PhotoGIMP Version
###############################################################################

get_installed_photogimp_version() {
    INSTALLED_PHOTOGIMP_VERSION=""

    # PhotoGIMP places its files in a versioned folder inside GIMP config
    # e.g. ~/Library/Application Support/GIMP/3.0/
    # We detect presence of the version folder and a marker file
    local MARKER="${GIMP_CONFIG_DIR}/${LATEST_PHOTOGIMP_VERSION}/tool-options"

    if [[ -d "${GIMP_CONFIG_DIR}/${LATEST_PHOTOGIMP_VERSION}" ]]; then
        # Check for PhotoGIMP-specific marker (it ships a custom menurc)
        if [[ -f "${GIMP_CONFIG_DIR}/${LATEST_PHOTOGIMP_VERSION}/menurc" ]] || \
           [[ -f "${GIMP_CONFIG_DIR}/${LATEST_PHOTOGIMP_VERSION}/gimprc" ]]; then
            # Read version tag we write on install
            local VERSION_FILE="${GIMP_CONFIG_DIR}/.photogimp_version"
            if [[ -f "$VERSION_FILE" ]]; then
                INSTALLED_PHOTOGIMP_VERSION=$(cat "$VERSION_FILE")
                log "Installed PhotoGIMP version: ${INSTALLED_PHOTOGIMP_VERSION}"
            else
                INSTALLED_PHOTOGIMP_VERSION="unknown"
                log "PhotoGIMP config found but no version marker. Treating as outdated."
            fi
        fi
    fi

    if [[ -z "$INSTALLED_PHOTOGIMP_VERSION" ]]; then
        log "PhotoGIMP not currently installed."
    fi
}

###############################################################################
# Download PhotoGIMP
###############################################################################

download_photogimp() {
    log "---------- Downloading PhotoGIMP ${LATEST_PHOTOGIMP_VERSION} ----------"

    local ZIP_PATH="${WORK_DIR}/PhotoGIMP.zip"

    log "URL: ${PHOTOGIMP_DOWNLOAD_URL}"
    /usr/bin/curl -fSL --max-time 120 --progress-bar \
        -L -o "$ZIP_PATH" "$PHOTOGIMP_DOWNLOAD_URL" >> "$LOG_FILE" 2>&1 \
        || fail "Failed to download PhotoGIMP from ${PHOTOGIMP_DOWNLOAD_URL}"

    log "Download complete: ${ZIP_PATH}"

    log "Extracting PhotoGIMP zip..."
    local EXTRACT_DIR="${WORK_DIR}/PhotoGIMP_extracted"
    mkdir -p "$EXTRACT_DIR"
    /usr/bin/unzip -q "$ZIP_PATH" -d "$EXTRACT_DIR" >> "$LOG_FILE" 2>&1 \
        || fail "Failed to extract PhotoGIMP zip."
    log "Extraction complete: ${EXTRACT_DIR}"

    # Locate the version folder inside the extracted zip
    # Structure: PhotoGIMP.zip → PhotoGIMP/ → 3.0/
    PHOTOGIMP_VERSION_FOLDER=$(find "$EXTRACT_DIR" -maxdepth 3 \
        -type d -name "${LATEST_PHOTOGIMP_VERSION}" | head -1)

    if [[ -z "$PHOTOGIMP_VERSION_FOLDER" ]]; then
        log "WARNING: Could not find folder named '${LATEST_PHOTOGIMP_VERSION}' in zip."
        log "Contents of extracted zip:"
        find "$EXTRACT_DIR" -maxdepth 4 >> "$LOG_FILE" 2>&1
        # Try to find any versioned config folder
        PHOTOGIMP_VERSION_FOLDER=$(find "$EXTRACT_DIR" -maxdepth 4 \
            -type d -name "[0-9]*.[0-9]*" | head -1)
        [[ -n "$PHOTOGIMP_VERSION_FOLDER" ]] \
            || fail "Could not locate PhotoGIMP version folder in extracted zip."
        log "Found version folder: ${PHOTOGIMP_VERSION_FOLDER}"
    else
        log "PhotoGIMP version folder: ${PHOTOGIMP_VERSION_FOLDER}"
    fi
}

###############################################################################
# Stage PhotoGIMP to /usr/local/share
###############################################################################

stage_photogimp() {
    log "---------- Staging PhotoGIMP to ${GIMP_SHARED_STAGING} ----------"

    rm -rf "$GIMP_SHARED_STAGING"
    mkdir -p "$GIMP_SHARED_STAGING"

    /bin/cp -R "${PHOTOGIMP_VERSION_FOLDER}" "${GIMP_SHARED_STAGING}/" \
        >> "$LOG_FILE" 2>&1 \
        || fail "Failed to copy PhotoGIMP version folder to staging dir."

    log "Staged: ${PHOTOGIMP_VERSION_FOLDER} → ${GIMP_SHARED_STAGING}/${LATEST_PHOTOGIMP_VERSION}"
}

###############################################################################
# Remove Old PhotoGIMP Version
###############################################################################

remove_old_photogimp() {
    log "---------- Removing Old PhotoGIMP Config ----------"

    # Remove the version config folder (e.g. 3.0/) — this is the PhotoGIMP data
    # We already backed up everything above, so this is safe
    local TARGET="${GIMP_CONFIG_DIR}/${LATEST_PHOTOGIMP_VERSION}"

    if [[ -d "$TARGET" ]]; then
        log "Removing existing config folder: ${TARGET}"
        rm -rf "$TARGET" \
            || fail "Could not remove old PhotoGIMP config: ${TARGET}"
        log "Removed: ${TARGET}"
    else
        log "No existing config folder to remove at ${TARGET}."
    fi

    # Also remove any old version folders that don't match current (e.g. 2.10)
    for OLD_DIR in "${GIMP_CONFIG_DIR}"/*/; do
        local DIRNAME
        DIRNAME=$(basename "$OLD_DIR")
        if [[ "$DIRNAME" != "$LATEST_PHOTOGIMP_VERSION" ]]; then
            log "Removing outdated version folder: ${OLD_DIR}"
            rm -rf "$OLD_DIR" >> "$LOG_FILE" 2>&1 \
                && log "  Removed: ${OLD_DIR}" \
                || log "  WARNING: Could not remove ${OLD_DIR}"
        fi
    done
}

###############################################################################
# Install PhotoGIMP
###############################################################################

install_photogimp() {
    log "---------- Installing PhotoGIMP ${LATEST_PHOTOGIMP_VERSION} ----------"

    local DEST="${GIMP_CONFIG_DIR}/${LATEST_PHOTOGIMP_VERSION}"

    # Ensure destination parent exists
    /bin/launchctl asuser "$CONSOLE_UID" \
        /usr/bin/su - "$CONSOLE_USER" -c \
        "mkdir -p '${GIMP_CONFIG_DIR}'" >> "$LOG_FILE" 2>&1

    log "Copying PhotoGIMP files from staging → ${DEST}"

    # Copy from staging (running as root so we have full read access)
    /bin/cp -R "${GIMP_SHARED_STAGING}/${LATEST_PHOTOGIMP_VERSION}" \
        "${GIMP_CONFIG_DIR}/" >> "$LOG_FILE" 2>&1 \
        || fail "Failed to copy PhotoGIMP to ${DEST}"

    log "PhotoGIMP files copied."

    # Write version marker so we can detect it on next run
    echo "$LATEST_PHOTOGIMP_VERSION" > "${GIMP_CONFIG_DIR}/.photogimp_version"
    log "Version marker written: ${GIMP_CONFIG_DIR}/.photogimp_version"
}

###############################################################################
# Fix Permissions
###############################################################################

fix_permissions() {
    log "---------- Fixing Permissions on GIMP Config ----------"

    # The entire GIMP config dir must be owned by the console user
    /usr/sbin/chown -R "${CONSOLE_USER}:staff" "$GIMP_CONFIG_DIR" \
        >> "$LOG_FILE" 2>&1 \
        || fail "Failed to set ownership on ${GIMP_CONFIG_DIR}"

    # Directories: 755, files: 644
    find "$GIMP_CONFIG_DIR" -type d -exec chmod 755 {} \; >> "$LOG_FILE" 2>&1
    find "$GIMP_CONFIG_DIR" -type f -exec chmod 644 {} \; >> "$LOG_FILE" 2>&1

    log "Permissions fixed: ${GIMP_CONFIG_DIR} → owner: ${CONSOLE_USER}:staff, dirs: 755, files: 644"
}

###############################################################################
# Validate Everything
###############################################################################

validate() {
    log "---------- Validation ----------"
    local ISSUES=0

    # GIMP.app
    if [[ -d "$GIMP_APP" ]]; then
        local INSTALLED_VER
        INSTALLED_VER=$(/usr/libexec/PlistBuddy -c \
            "Print :CFBundleShortVersionString" \
            "${GIMP_APP}/Contents/Info.plist" 2>/dev/null)
        log "  OK: GIMP.app installed — version ${INSTALLED_VER}"
    else
        log "  FAIL: GIMP.app not found at ${GIMP_APP}"
        ISSUES=$((ISSUES + 1))
    fi

    # PhotoGIMP config folder
    local PHOTOGIMP_DEST="${GIMP_CONFIG_DIR}/${LATEST_PHOTOGIMP_VERSION}"
    if [[ -d "$PHOTOGIMP_DEST" ]]; then
        local FILE_COUNT
        FILE_COUNT=$(find "$PHOTOGIMP_DEST" -type f | wc -l | xargs)
        log "  OK: PhotoGIMP config installed — ${FILE_COUNT} files at ${PHOTOGIMP_DEST}"
    else
        log "  FAIL: PhotoGIMP config folder not found at ${PHOTOGIMP_DEST}"
        ISSUES=$((ISSUES + 1))
    fi

    # Ownership check
    local OWNER
    OWNER=$(stat -f "%Su" "$GIMP_CONFIG_DIR" 2>/dev/null)
    if [[ "$OWNER" == "$CONSOLE_USER" ]]; then
        log "  OK: ${GIMP_CONFIG_DIR} owned by ${CONSOLE_USER}"
    else
        log "  WARN: ${GIMP_CONFIG_DIR} owned by ${OWNER}, expected ${CONSOLE_USER}"
        ISSUES=$((ISSUES + 1))
    fi

    # Version marker
    if [[ -f "${GIMP_CONFIG_DIR}/.photogimp_version" ]]; then
        local MARKED_VER
        MARKED_VER=$(cat "${GIMP_CONFIG_DIR}/.photogimp_version")
        log "  OK: Version marker present — PhotoGIMP ${MARKED_VER}"
    else
        log "  WARN: Version marker file missing"
        ISSUES=$((ISSUES + 1))
    fi

    if [[ $ISSUES -eq 0 ]]; then
        log "Validation passed. All components in place."
    else
        log "Validation completed with ${ISSUES} issue(s). Review log."
    fi
}

###############################################################################
# Summary
###############################################################################

print_summary() {
    local INSTALLED_GIMP_VER
    INSTALLED_GIMP_VER=$(/usr/libexec/PlistBuddy -c \
        "Print :CFBundleShortVersionString" \
        "${GIMP_APP}/Contents/Info.plist" 2>/dev/null || echo "unknown")

    log "=================================================="
    log "INSTALLATION SUMMARY"
    log "=================================================="
    log "Status              : SUCCESS"
    log "User                : ${CONSOLE_USER} (UID: ${CONSOLE_UID})"
    log "Architecture        : ${ARCH} (${GIMP_DMG_ARCH})"
    log "macOS               : $(sw_vers -productVersion)"
    log "--------------------------------------------------"
    log "GIMP                : ${INSTALLED_GIMP_VER} (latest: ${LATEST_GIMP_VERSION})"
    log "GIMP installed at   : ${GIMP_APP}"
    log "PhotoGIMP           : ${LATEST_PHOTOGIMP_VERSION}"
    log "PhotoGIMP config    : ${GIMP_CONFIG_DIR}/${LATEST_PHOTOGIMP_VERSION}"
    if [[ -n "${GIMP_BACKUP_PATH:-}" ]]; then
        log "Config backup       : ${GIMP_BACKUP_PATH}"
    else
        log "Config backup       : N/A (no prior config)"
    fi
    log "Log file            : ${LOG_FILE}"
    log "--------------------------------------------------"
    log "NOTE: Open GIMP — you should see the PhotoGIMP layout."
    log "      To revert: restore from backup at ${GIMP_BACKUP_PATH:-/Users/Shared/}"
    log "=================================================="
}

###############################################################################
# Main
###############################################################################

main() {

    touch "$LOG_FILE" 2>/dev/null \
        || { echo "ERROR: Cannot create log file at $LOG_FILE"; exit 1; }
    chmod 644 "$LOG_FILE"

    rotate_log
    mkdir -p "$WORK_DIR"

    log "=================================================="
    log "GIMP + PhotoGIMP Installation Started"
    log "=================================================="

    # Pre-flight
    check_root
    check_console_user
    detect_arch
    check_network
    check_disk_space

    # Get latest versions
    get_latest_gimp_version
    get_latest_photogimp_version

    # ── GIMP: Install or upgrade ──────────────────────────────────────────────
    log "---------- GIMP Check ----------"
    if get_installed_gimp_version; then
        if version_gt "$LATEST_GIMP_VERSION" "$INSTALLED_GIMP_VERSION"; then
            log "GIMP is outdated (installed: ${INSTALLED_GIMP_VERSION}, latest: ${LATEST_GIMP_VERSION}). Upgrading..."
            install_gimp
        else
            log "GIMP ${INSTALLED_GIMP_VERSION} is current. Skipping GIMP install."
        fi
    else
        log "GIMP not installed. Installing ${LATEST_GIMP_VERSION}..."
        install_gimp
    fi

    # ── Initialize GIMP config dirs ───────────────────────────────────────────
    initialize_gimp_config

    # ── PhotoGIMP: Install or upgrade ─────────────────────────────────────────
    log "---------- PhotoGIMP Check ----------"
    get_installed_photogimp_version

    local NEEDS_PHOTOGIMP_INSTALL=0

    if [[ -z "$INSTALLED_PHOTOGIMP_VERSION" ]]; then
        log "PhotoGIMP not installed. Will install ${LATEST_PHOTOGIMP_VERSION}."
        NEEDS_PHOTOGIMP_INSTALL=1
    elif [[ "$INSTALLED_PHOTOGIMP_VERSION" == "unknown" ]]; then
        log "PhotoGIMP version unknown. Reinstalling ${LATEST_PHOTOGIMP_VERSION}."
        NEEDS_PHOTOGIMP_INSTALL=1
    elif version_gt "$LATEST_PHOTOGIMP_VERSION" "$INSTALLED_PHOTOGIMP_VERSION"; then
        log "PhotoGIMP is outdated (installed: ${INSTALLED_PHOTOGIMP_VERSION}, latest: ${LATEST_PHOTOGIMP_VERSION}). Upgrading..."
        NEEDS_PHOTOGIMP_INSTALL=1
    else
        log "PhotoGIMP ${INSTALLED_PHOTOGIMP_VERSION} is current. Skipping PhotoGIMP install."
    fi

    if [[ $NEEDS_PHOTOGIMP_INSTALL -eq 1 ]]; then
        backup_gimp_config
        download_photogimp
        stage_photogimp
        remove_old_photogimp
        install_photogimp
        fix_permissions
    fi

    # ── Validate ──────────────────────────────────────────────────────────────
    validate

    # ── Summary ───────────────────────────────────────────────────────────────
    print_summary

    # ── Cleanup ───────────────────────────────────────────────────────────────
    cleanup_workdir

    exit 0
}

main
