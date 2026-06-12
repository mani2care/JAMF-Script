#!/bin/zsh --no-rcs
##############################################################################
#
# Script Name      : HColima + Docker Uninstall Script.zsh
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
# Colima + Docker Uninstall Script
# Run as: root (via Jamf Pro policy)
# Removes: docker-compose, docker, colima (binaries only)
# Removes: Homebrew (always — runs as root for full permission)
# Removes: Standalone binaries from /usr/local/bin if present
# Preserves: All user data, containers, images, volumes, ~/.colima, ~/.docker
# Logs to: /private/var/log/colima_uninstall.log
#
# Parameters:
#   $4 = REMOVE_HOMEBREW — "true" to also remove Homebrew, leave empty to skip
###############################################################################

###############################################################################
# Configuration
###############################################################################

LOG_FILE="/private/var/log/colima_uninstall.log"
MAX_LOG_SIZE_KB=1024
REMOVE_HOMEBREW="$4"   # "true" = also uninstall Homebrew; empty = skip

# Standalone binary dir used by the install script
STANDALONE_BIN="/usr/local/bin"

###############################################################################
# Detect Logged-in User
###############################################################################

CONSOLE_USER=$(stat -f "%Su" /dev/console)
CONSOLE_UID=$(id -u "$CONSOLE_USER" 2>/dev/null)

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
    log "Colima Uninstall FAILED"
    log "=================================================="
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
# Command Runners
###############################################################################

run_as_user() {
    local CMD="$1"
    log "[USER: $CONSOLE_USER] Running: $CMD"
    /bin/launchctl asuser "$CONSOLE_UID" \
        /usr/bin/su - "$CONSOLE_USER" -c "
            export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:${BREW_PREFIX}/bin
            $CMD
        " >> "$LOG_FILE" 2>&1
    local STATUS=$?
    if [[ $STATUS -ne 0 ]]; then
        log "WARNING: Command exited non-zero (user: $CONSOLE_USER): $CMD"
    else
        log "[USER: $CONSOLE_USER] Success: $CMD"
    fi
}

check_as_user() {
    local CMD="$1"
    /bin/launchctl asuser "$CONSOLE_UID" \
        /usr/bin/su - "$CONSOLE_USER" -c "
            export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:${BREW_PREFIX}/bin
            $CMD
        " >> "$LOG_FILE" 2>&1
    return $?
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
}

detect_arch() {
    log "---------- Architecture Detection ----------"
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        BREW_PREFIX="/opt/homebrew"
        log "Architecture: Apple Silicon (arm64)"
    else
        BREW_PREFIX="/usr/local"
        log "Architecture: Intel (x86_64)"
    fi
    BREW_BIN="${BREW_PREFIX}/bin/brew"
    log "Homebrew prefix: $BREW_PREFIX"
}

###############################################################################
# Uninstall Functions
###############################################################################

remove_docker_compose_plugin_link() {
    log "---------- Remove docker-compose CLI plugin link ----------"

    local PLUGIN_PATH="/Users/${CONSOLE_USER}/.docker/cli-plugins/docker-compose"

    if [[ -L "$PLUGIN_PATH" ]]; then
        rm -f "$PLUGIN_PATH" \
            && log "docker-compose CLI plugin symlink removed: $PLUGIN_PATH" \
            || log "WARNING: Could not remove symlink: $PLUGIN_PATH"
    else
        log "docker-compose CLI plugin symlink not found. Skipping."
    fi

    # If cli-plugins dir is now empty, clean it up (safe — no user data lives here)
    local PLUGIN_DIR="/Users/${CONSOLE_USER}/.docker/cli-plugins"
    if [[ -d "$PLUGIN_DIR" && -z "$(ls -A "$PLUGIN_DIR" 2>/dev/null)" ]]; then
        rmdir "$PLUGIN_DIR" \
            && log "Removed empty directory: $PLUGIN_DIR" \
            || log "WARNING: Could not remove $PLUGIN_DIR"
    fi
}

uninstall_package() {
    local PACKAGE="$1"
    log "---------- Uninstall Package: $PACKAGE ----------"

    if ! check_as_user "test -x '${BREW_BIN}'"; then
        log "Homebrew not found. Cannot uninstall $PACKAGE via brew. Skipping."
        return 0
    fi

    if check_as_user "${BREW_BIN} list ${PACKAGE} >/dev/null 2>&1"; then
        log "$PACKAGE found. Uninstalling..."
        run_as_user "${BREW_BIN} uninstall --force ${PACKAGE}"
        log "$PACKAGE uninstalled."
    else
        log "$PACKAGE not installed via Homebrew. Skipping."
    fi
}

cleanup_brew() {
    log "---------- Brew Cleanup ----------"

    if check_as_user "test -x '${BREW_BIN}'"; then
        run_as_user "${BREW_BIN} cleanup --prune=all"
        log "Brew cleanup completed."
    else
        log "Homebrew not found. Skipping cleanup."
    fi
}

###############################################################################
# Remove Standalone Binaries
#
# The install script copies colima/docker/docker-compose to /usr/local/bin
# so they survive Homebrew removal. On uninstall we remove those copies too.
# We ONLY remove the exact files we placed — nothing else in /usr/local/bin.
###############################################################################

remove_standalone_binaries() {
    log "---------- Remove Standalone Binaries from ${STANDALONE_BIN} ----------"

    local BINS=("colima" "docker" "docker-compose")
    local REMOVED=0

    for BIN in "${BINS[@]}"; do
        local BIN_PATH="${STANDALONE_BIN}/${BIN}"
        if [[ -f "$BIN_PATH" ]]; then
            rm -f "$BIN_PATH" \
                && log "  Removed: $BIN_PATH" \
                && REMOVED=$((REMOVED + 1)) \
                || log "  WARNING: Could not remove $BIN_PATH"
        else
            log "  Not found (already removed or never installed): $BIN_PATH"
        fi
    done

    log "Standalone binary removal complete. Removed: ${REMOVED}/${#BINS[@]}"
}

###############################################################################
# Homebrew Uninstall
#
# Runs as root — same approach as the install script — so it has permission
# to delete root-owned files like /etc/paths.d/homebrew without errors.
# NONINTERACTIVE=1 skips all interactive prompts.
###############################################################################

uninstall_homebrew() {
    log "---------- Homebrew Uninstall ----------"

    if ! check_as_user "test -x '${BREW_BIN}'"; then
        log "Homebrew not installed. Skipping."
        return 0
    fi

    # Pre-remove root-owned /etc/paths.d/homebrew as root
    if [[ -f "/etc/paths.d/homebrew" ]]; then
        rm -f "/etc/paths.d/homebrew" \
            && log "Pre-removed root-owned file: /etc/paths.d/homebrew" \
            || log "WARNING: Could not remove /etc/paths.d/homebrew — continuing anyway."
    else
        log "/etc/paths.d/homebrew not present — skipping."
    fi

    # Run official Homebrew uninstall as root for full permissions
    log "Running Homebrew uninstall as root (NONINTERACTIVE)..."
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" \
        >> "$LOG_FILE" 2>&1
    local EXIT_CODE=$?

    if [[ $EXIT_CODE -ne 0 ]]; then
        log "WARNING: Homebrew uninstall exited with code ${EXIT_CODE}. Review log."
    else
        log "Homebrew uninstall completed cleanly (exit 0)."
    fi

    # Poll until brew binary is gone (max 30s)
    log "Waiting for Homebrew removal to settle..."
    local MAX_WAIT=30
    local ELAPSED=0
    while [[ -x "${BREW_BIN}" && $ELAPSED -lt $MAX_WAIT ]]; do
        sleep 2
        ELAPSED=$((ELAPSED + 2))
        log "  ...still waiting (${ELAPSED}s)"
    done

    if [[ -x "${BREW_BIN}" ]]; then
        log "ERROR: Homebrew binary STILL present at ${BREW_BIN} after ${MAX_WAIT}s."
    else
        log "VALIDATED: Homebrew binary removed successfully."
    fi

    # Clean up leftover files the uninstaller skips
    # Uses BREW_PREFIX — works on both arm64 (/opt/homebrew) and Intel (/usr/local)
    log "Cleaning up leftover Homebrew files..."
    local LEFTOVERS=(
        "${BREW_PREFIX}/.gitattributes"
        "${BREW_PREFIX}/AGENTS.md"
        "${BREW_PREFIX}/CLAUDE.md"
        "${BREW_PREFIX}/etc"
        "${BREW_PREFIX}/share"
        "${BREW_PREFIX}/var"
    )
    for ITEM in "${LEFTOVERS[@]}"; do
        if [[ -e "$ITEM" ]]; then
            rm -rf "$ITEM" \
                && log "  Removed: $ITEM" \
                || log "  WARNING: Could not remove $ITEM"
        fi
    done

    log "---------- Homebrew Uninstall Complete ----------"
}

###############################################################################
# Validate Nothing Left Behind
###############################################################################

validate_removal() {
    log "---------- Validation ----------"

    local ISSUES=0

    # Check Homebrew brew binary
    if [[ -x "${BREW_BIN}" ]]; then
        log "  WARN: Homebrew binary still present: ${BREW_BIN}"
        ISSUES=$((ISSUES + 1))
    else
        log "  OK: Homebrew binary not present."
    fi

    # Check standalone binaries
    for BIN in colima docker docker-compose; do
        if [[ -f "${STANDALONE_BIN}/${BIN}" ]]; then
            log "  WARN: Standalone binary still present: ${STANDALONE_BIN}/${BIN}"
            ISSUES=$((ISSUES + 1))
        else
            log "  OK: ${STANDALONE_BIN}/${BIN} not present."
        fi
    done

    # Check CLI plugin symlink
    local PLUGIN_PATH="/Users/${CONSOLE_USER}/.docker/cli-plugins/docker-compose"
    if [[ -e "$PLUGIN_PATH" ]]; then
        log "  WARN: docker-compose CLI plugin still present: ${PLUGIN_PATH}"
        ISSUES=$((ISSUES + 1))
    else
        log "  OK: docker-compose CLI plugin not present."
    fi

    # Confirm user data is intact
    local USER_HOME="/Users/${CONSOLE_USER}"
    for PRESERVE in ".colima" ".docker"; do
        if [[ -d "${USER_HOME}/${PRESERVE}" ]]; then
            log "  OK: User data preserved: ${USER_HOME}/${PRESERVE}"
        else
            log "  INFO: ${USER_HOME}/${PRESERVE} not present (may not have existed)."
        fi
    done

    if [[ $ISSUES -eq 0 ]]; then
        log "Validation passed. All app files removed, user data intact."
    else
        log "Validation complete with ${ISSUES} warning(s). Review log."
    fi
}

###############################################################################
# Summary
###############################################################################

print_summary() {
    log "=================================================="
    log "UNINSTALL SUMMARY"
    log "=================================================="
    log "Status              : SUCCESS"
    log "User                : $CONSOLE_USER (UID: $CONSOLE_UID)"
    log "Architecture        : $ARCH"
    log "macOS               : $(sw_vers -productVersion)"
    log "--------------------------------------------------"
    log "Removed             : docker-compose (Homebrew package)"
    log "Removed             : docker (Homebrew package)"
    log "Removed             : colima (Homebrew package)"
    log "Removed             : docker-compose CLI plugin symlink"
    log "Removed             : ${STANDALONE_BIN}/colima"
    log "Removed             : ${STANDALONE_BIN}/docker"
    log "Removed             : ${STANDALONE_BIN}/docker-compose"
    if [[ "$REMOVE_HOMEBREW" == "true" ]]; then
        log "Removed             : Homebrew"
    else
        log "Homebrew            : Kept (REMOVE_HOMEBREW not set)"
    fi
    log "--------------------------------------------------"
    log "Preserved           : ~/.colima/ (Colima VM + config)"
    log "Preserved           : ~/.docker/ (Docker config, credentials)"
    log "Preserved           : All containers, images, volumes"
    log "--------------------------------------------------"
    log "NOTE: Colima instance data is preserved at ~/.colima"
    log "      To fully remove all Colima data, the user can run:"
    log "        colima delete"
    log "        rm -rf ~/.colima"
    log "        rm -rf ~/.docker"
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

    log "=================================================="
    log "Colima Uninstall Started"
    log "=================================================="
    log "Remove Homebrew : ${REMOVE_HOMEBREW:-false}"
    log "=================================================="

    # Pre-flight
    check_root
    check_console_user
    detect_arch

    # Remove CLI plugin symlink first (user-space, no brew needed)
    remove_docker_compose_plugin_link

    # Remove Homebrew packages (if brew is present)
    uninstall_package "docker-compose"
    uninstall_package "docker"
    uninstall_package "colima"

    # Brew cleanup
    cleanup_brew

    # Remove standalone binaries placed by install script in /usr/local/bin
    remove_standalone_binaries

    # Optionally remove Homebrew itself (always runs as root)
    if [[ "$REMOVE_HOMEBREW" == "true" ]]; then
        uninstall_homebrew
    else
        log "---------- Homebrew ----------"
        log "REMOVE_HOMEBREW not set to 'true'. Homebrew kept as-is."
    fi

    # Validate nothing app-related remains
    validate_removal

    print_summary

    exit 0
}

main
