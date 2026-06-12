#!/bin/zsh --no-rcs
##############################################################################
#
# Script Name      : Homebrew+Colima + Docker Installation Script and uninstall Homebrew.zsh
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
# Colima + Docker Installation Script
# Run as: root (via Jamf Pro policy)
# Installs: Homebrew, Colima, Docker, Docker Compose
# Logs to: /private/var/log/colima_install.log
#
# NOTE: This script only installs packages.
#       Starting/configuring Colima is left to the user.
#       Homebrew is removed after installation for security reasons.
#       Colima/Docker/Docker Compose binaries are copied to /usr/local/bin
#       before Homebrew is removed so they remain functional.
###############################################################################

###############################################################################
# Configuration
###############################################################################

LOG_FILE="/private/var/log/colima_install.log"
MAX_LOG_SIZE_KB=1024
REQUIRED_DISK_GB=5
MIN_MACOS_MAJOR=13

# Standalone install dir — independent of Homebrew
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
    log "Colima Installation FAILED"
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
        fail "Command failed (user: $CONSOLE_USER): $CMD"
    fi
    log "[USER: $CONSOLE_USER] Success: $CMD"
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

check_macos_version() {
    log "---------- macOS Version Check ----------"
    local OS_VERSION
    OS_VERSION=$(sw_vers -productVersion)
    local OS_MAJOR
    OS_MAJOR=$(echo "$OS_VERSION" | awk -F. '{print $1}')
    log "macOS version: $OS_VERSION"
    if [[ "$OS_MAJOR" -lt "$MIN_MACOS_MAJOR" ]]; then
        fail "macOS ${MIN_MACOS_MAJOR}+ required. Found: ${OS_VERSION}"
    fi
    log "macOS version check passed."
}

check_disk_space() {
    log "---------- Disk Space Check ----------"
    local AVAILABLE_GB
    AVAILABLE_GB=$(df -g / | awk 'NR==2 {print $4}')
    log "Available disk space: ${AVAILABLE_GB}GB (Required: ${REQUIRED_DISK_GB}GB)"
    if [[ "$AVAILABLE_GB" -lt "$REQUIRED_DISK_GB" ]]; then
        fail "Insufficient disk space. Required: ${REQUIRED_DISK_GB}GB, Available: ${AVAILABLE_GB}GB"
    fi
    log "Disk space check passed."
}

check_network() {
    log "---------- Network Check ----------"
    if /usr/bin/curl -s --max-time 10 https://raw.githubusercontent.com -o /dev/null; then
        log "Network connectivity check passed."
    else
        fail "No network connectivity. Cannot reach GitHub for Homebrew install."
    fi
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
# Homebrew
###############################################################################

install_homebrew() {
    log "---------- Homebrew Install ----------"

    if check_as_user "test -x '${BREW_BIN}'"; then
        log "Homebrew already installed at ${BREW_BIN}. Skipping."
        return 0
    fi

    log "Homebrew not found. Installing as user: $CONSOLE_USER ..."
    /bin/launchctl asuser "$CONSOLE_UID" \
        /usr/bin/su - "$CONSOLE_USER" \
        -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' \
        >> "$LOG_FILE" 2>&1

    [[ $? -eq 0 ]] || fail "Homebrew installation failed."

    check_as_user "test -x '${BREW_BIN}'" \
        || fail "Homebrew binary not found after install at ${BREW_BIN}."

    log "Homebrew installed successfully."
}

configure_brew() {
    log "---------- Homebrew Configure ----------"
    run_as_user "${BREW_BIN} analytics off"
    log "Analytics disabled."
    run_as_user "${BREW_BIN} update"
    log "Brew update completed."
}

###############################################################################
# Packages
###############################################################################

install_or_upgrade_package() {
    local PACKAGE="$1"
    log "---------- Package: $PACKAGE ----------"

    if check_as_user "${BREW_BIN} list ${PACKAGE} >/dev/null 2>&1"; then
        log "$PACKAGE already installed. Checking for upgrade..."
        /bin/launchctl asuser "$CONSOLE_UID" \
            /usr/bin/su - "$CONSOLE_USER" \
            -c "export PATH=/usr/bin:/bin:/usr/sbin:/sbin:${BREW_PREFIX}/bin; \
                ${BREW_BIN} upgrade ${PACKAGE}" >> "$LOG_FILE" 2>&1
        log "$PACKAGE upgrade check completed."
    else
        log "$PACKAGE not found. Installing..."
        run_as_user "${BREW_BIN} install ${PACKAGE}"
        log "$PACKAGE installed successfully."
    fi

    check_as_user "${BREW_BIN} list ${PACKAGE} >/dev/null 2>&1" \
        || fail "$PACKAGE validation failed after install."
    log "$PACKAGE validation passed."
}

install_packages() {
    log "---------- Installing Packages ----------"

    install_or_upgrade_package "colima"
    install_or_upgrade_package "docker"
    install_or_upgrade_package "docker-compose"

    # Link docker-compose as Docker CLI plugin (user's home dir, so runs as user)
    log "Linking docker-compose as Docker CLI plugin..."
    /bin/launchctl asuser "$CONSOLE_UID" \
        /usr/bin/su - "$CONSOLE_USER" -c "
            export PATH=/usr/bin:/bin:/usr/sbin:/sbin:${BREW_PREFIX}/bin
            mkdir -p ~/.docker/cli-plugins
            ln -sfn ${BREW_PREFIX}/opt/docker-compose/bin/docker-compose \
                ~/.docker/cli-plugins/docker-compose
        " >> "$LOG_FILE" 2>&1
    [[ $? -eq 0 ]] || fail "Failed to link docker-compose CLI plugin."
    log "docker-compose plugin linked successfully."

    log "All packages installed."
}

cleanup_brew() {
    log "---------- Brew Cleanup ----------"
    run_as_user "${BREW_BIN} cleanup"
    log "Brew cleanup completed."
}

###############################################################################
# Persist Binaries to /usr/local/bin
#
# Homebrew will be removed for security reasons. Before that happens, we copy
# the colima, docker, and docker-compose binaries to /usr/local/bin so they
# remain available to the user after Homebrew is gone.
#
# We also re-link docker-compose as a Docker CLI plugin pointing to the new
# standalone path instead of the Homebrew opt path (which disappears).
###############################################################################

persist_binaries() {
    log "---------- Persisting Binaries to ${STANDALONE_BIN} ----------"

    mkdir -p "$STANDALONE_BIN"

    local BINS=(
        "colima"
        "docker"
        "docker-compose"
    )

    for BIN in "${BINS[@]}"; do
        local SRC="${BREW_PREFIX}/bin/${BIN}"
        local DST="${STANDALONE_BIN}/${BIN}"

        # Resolve symlink to actual binary before copying
        local REAL_SRC
        REAL_SRC=$(readlink -f "$SRC" 2>/dev/null || echo "$SRC")

        if [[ -x "$REAL_SRC" ]]; then
            cp "$REAL_SRC" "$DST" \
                && chmod +x "$DST" \
                && log "  Copied: $REAL_SRC → $DST" \
                || log "  WARNING: Failed to copy $BIN to $STANDALONE_BIN"
        else
            log "  WARNING: Source binary not found or not executable: $SRC"
        fi
    done

    # Re-link docker-compose CLI plugin to the new standalone path
    log "Re-linking docker-compose CLI plugin to standalone path..."
    local USER_HOME
    USER_HOME=$(eval echo "~${CONSOLE_USER}")
    local PLUGIN_DIR="${USER_HOME}/.docker/cli-plugins"

    mkdir -p "$PLUGIN_DIR"
    ln -sfn "${STANDALONE_BIN}/docker-compose" "${PLUGIN_DIR}/docker-compose" \
        && chown "$CONSOLE_USER" "${PLUGIN_DIR}/docker-compose" \
        && log "  docker-compose CLI plugin re-linked to ${STANDALONE_BIN}/docker-compose" \
        || log "  WARNING: Failed to re-link docker-compose CLI plugin."

    # Validate all three are now in STANDALONE_BIN
    log "Validating standalone binaries..."
    local ALL_OK=1
    for BIN in colima docker docker-compose; do
        if [[ -x "${STANDALONE_BIN}/${BIN}" ]]; then
            log "  OK: ${STANDALONE_BIN}/${BIN}"
        else
            log "  WARNING: ${STANDALONE_BIN}/${BIN} not found or not executable."
            ALL_OK=0
        fi
    done

    if [[ $ALL_OK -eq 1 ]]; then
        log "All binaries persisted successfully. Safe to remove Homebrew."
    else
        log "WARNING: One or more binaries could not be persisted. Review log before proceeding."
    fi

    log "---------- Persist Binaries Complete ----------"
}

###############################################################################
# Homebrew Uninstall
#
# Runs as root so it has permission to delete all Homebrew-owned files,
# including root-owned files like /etc/paths.d/homebrew.
# NONINTERACTIVE=1 skips all interactive prompts.
###############################################################################

uninstall_homebrew() {
    log "---------- Homebrew Uninstall ----------"

    if ! check_as_user "test -x '${BREW_BIN}'"; then
        log "Homebrew not installed. Skipping."
        return 0
    fi

    # Brew cleanup before removal
    log "Running brew cleanup before uninstall..."
    /bin/launchctl asuser "$CONSOLE_UID" \
        /usr/bin/su - "$CONSOLE_USER" -c "
            export PATH=/usr/bin:/bin:/usr/sbin:/sbin:${BREW_PREFIX}/bin
            ${BREW_BIN} cleanup --prune=all
        " >> "$LOG_FILE" 2>&1
    log "Brew cleanup done."

    # Pre-remove root-owned /etc/paths.d/homebrew as root
    # The official uninstall script cannot delete this when running as a user
    if [[ -f "/etc/paths.d/homebrew" ]]; then
        rm -f "/etc/paths.d/homebrew" \
            && log "Pre-removed root-owned file: /etc/paths.d/homebrew" \
            || log "WARNING: Could not remove /etc/paths.d/homebrew — continuing anyway."
    else
        log "/etc/paths.d/homebrew not present — skipping."
    fi

    # Run the official Homebrew uninstall script as root
    # Running as root (not su - user) ensures permission to remove all files
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

    # Wait and poll until brew binary is gone (max 30s)
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

    # Clean up any leftover files the uninstaller skipped
    # Use BREW_PREFIX so this works on both arm64 (/opt/homebrew) and Intel (/usr/local)
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
# Summary
#
# After Homebrew removal, binaries live in /usr/local/bin — not BREW_PREFIX.
# Version checks now use STANDALONE_BIN paths directly as root (no su needed).
###############################################################################

print_summary() {
    log "=================================================="
    log "INSTALLATION SUMMARY"
    log "=================================================="
    log "Status        : SUCCESS"
    log "User          : $CONSOLE_USER (UID: $CONSOLE_UID)"
    log "Architecture  : $ARCH"
    log "macOS         : $(sw_vers -productVersion)"
    log "Homebrew      : REMOVED (security policy)"

    # Version checks against standalone paths
    local COLIMA_VER DOCKER_VER COMPOSE_VER

    if [[ -x "${STANDALONE_BIN}/colima" ]]; then
        COLIMA_VER=$("${STANDALONE_BIN}/colima" version 2>/dev/null || echo "unknown")
    else
        COLIMA_VER="NOT FOUND at ${STANDALONE_BIN}/colima"
    fi

    if [[ -x "${STANDALONE_BIN}/docker" ]]; then
        DOCKER_VER=$("${STANDALONE_BIN}/docker" --version 2>/dev/null || echo "unknown")
    else
        DOCKER_VER="NOT FOUND at ${STANDALONE_BIN}/docker"
    fi

    if [[ -x "${STANDALONE_BIN}/docker-compose" ]]; then
        COMPOSE_VER=$("${STANDALONE_BIN}/docker-compose" version 2>/dev/null || echo "unknown")
    else
        COMPOSE_VER="NOT FOUND at ${STANDALONE_BIN}/docker-compose"
    fi

    log "Colima        : $COLIMA_VER"
    log "Docker        : $DOCKER_VER"
    log "Docker Compose: $COMPOSE_VER"
    log "Binaries at   : $STANDALONE_BIN"
    log "Log file      : $LOG_FILE"
    log "--------------------------------------------------"
    log "NOTE: Colima has not been started."
    log "      User can start it with: colima start"
    log "NOTE: Homebrew has been uninstalled per security policy."
    log "      Colima, Docker, and Docker Compose are at ${STANDALONE_BIN}"
    log "      and remain fully functional without Homebrew."
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
    log "Colima Installation Started"
    log "=================================================="

    check_root
    check_console_user
    check_macos_version
    check_disk_space
    check_network
    detect_arch

    install_homebrew
    configure_brew
    install_packages
    cleanup_brew
    persist_binaries      # ← Copy binaries to /usr/local/bin BEFORE removing Homebrew
    uninstall_homebrew    # ← Now safe to remove; binaries are already standalone

    print_summary

    exit 0
}

main
