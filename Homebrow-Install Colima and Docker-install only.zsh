#!/bin/zsh --no-rcs
##############################################################################
#
# Script Name      : Colima + Docker Installation Script no homebrew uninstall.zsh
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
###############################################################################

###############################################################################
# Configuration
###############################################################################

LOG_FILE="/private/var/log/colima_install.log"
MAX_LOG_SIZE_KB=1024
REQUIRED_DISK_GB=5
MIN_MACOS_MAJOR=13

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

    # Link docker-compose as Docker CLI plugin
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
# Summary
###############################################################################

print_summary() {
    local COLIMA_VER
    COLIMA_VER=$(/bin/launchctl asuser "$CONSOLE_UID" \
        /usr/bin/su - "$CONSOLE_USER" \
        -c "export PATH=/usr/bin:/bin:/usr/sbin:/sbin:${BREW_PREFIX}/bin; \
            ${BREW_PREFIX}/bin/colima version 2>/dev/null" || echo "unknown")

    local DOCKER_VER
    DOCKER_VER=$(/bin/launchctl asuser "$CONSOLE_UID" \
        /usr/bin/su - "$CONSOLE_USER" \
        -c "export PATH=/usr/bin:/bin:/usr/sbin:/sbin:${BREW_PREFIX}/bin; \
            ${BREW_PREFIX}/bin/docker --version 2>/dev/null" || echo "unknown")

    local COMPOSE_VER
    COMPOSE_VER=$(/bin/launchctl asuser "$CONSOLE_UID" \
        /usr/bin/su - "$CONSOLE_USER" \
        -c "export PATH=/usr/bin:/bin:/usr/sbin:/sbin:${BREW_PREFIX}/bin; \
            ${BREW_PREFIX}/bin/docker compose version 2>/dev/null" || echo "unknown")

    log "=================================================="
    log "INSTALLATION SUMMARY"
    log "=================================================="
    log "Status        : SUCCESS"
    log "User          : $CONSOLE_USER (UID: $CONSOLE_UID)"
    log "Architecture  : $ARCH"
    log "macOS         : $(sw_vers -productVersion)"
    log "Homebrew      : $BREW_PREFIX"
    log "Colima        : $COLIMA_VER"
    log "Docker        : $DOCKER_VER"
    log "Docker Compose: $COMPOSE_VER"
    log "Log file      : $LOG_FILE"
    log "--------------------------------------------------"
    log "NOTE: Colima has not been started."
    log "      User can start it with: colima start"
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

    print_summary

    exit 0
}

main
