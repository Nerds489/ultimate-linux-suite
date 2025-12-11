#!/usr/bin/env bash
#
# utils.sh - Core utility functions for Ultimate Linux Suite
#
# Provides common helper functions used throughout the suite
#

# Prevent multiple sourcing
[[ -n "${_UTILS_SH_LOADED:-}" ]] && return 0
readonly _UTILS_SH_LOADED=1

# Suite version
declare -gr SUITE_VERSION="1.0.0"
declare -gr SUITE_NAME="Ultimate Linux Suite"

# Check if running as root
# Returns: 0 if root, 1 otherwise
is_root() {
    [[ "$(id -u)" -eq 0 ]]
}

# Require root privileges or exit
# Arguments:
#   $1 - Custom error message (optional)
require_root() {
    if ! is_root; then
        local msg="${1:-This operation requires root privileges}"
        log_error "$msg"
        log_info "Please run with sudo or as root"
        exit 1
    fi
}

# Check if a command exists
# Arguments:
#   $1 - Command name
# Returns: 0 if exists, 1 otherwise
have_cmd() {
    command -v "$1" &>/dev/null
}

# Require a command or exit
# Arguments:
#   $1 - Command name
#   $2 - Package suggestion (optional)
require_cmd() {
    local cmd="$1"
    local pkg="${2:-$cmd}"

    if ! have_cmd "$cmd"; then
        log_error "Required command not found: $cmd"
        log_info "Try installing: $pkg"
        exit 1
    fi
}

# Run a command with error handling
# Arguments:
#   $@ - Command and arguments
# Returns: Command exit code
safe_run() {
    local cmd="$*"
    log_debug "Running: $cmd"

    if ! "$@"; then
        local exit_code=$?
        log_error "Command failed (exit $exit_code): $cmd"
        return $exit_code
    fi
    return 0
}

# Run a command silently (output only on error)
# Arguments:
#   $@ - Command and arguments
# Returns: Command exit code
quiet_run() {
    local output
    local exit_code

    output=$("$@" 2>&1)
    exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log_error "Command failed: $*"
        log_error "Output: $output"
    fi

    return $exit_code
}

# Run a command with sudo if not root
# Arguments:
#   $@ - Command and arguments
run_as_root() {
    if is_root; then
        "$@"
    else
        sudo "$@"
    fi
}

# Confirm an action with the user
# Arguments:
#   $1 - Prompt message
#   $2 - Default (y/n, optional, default n)
# Returns: 0 for yes, 1 for no
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local response

    if [[ "${default,,}" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    read -r -p "$prompt" response
    response="${response:-$default}"

    [[ "${response,,}" =~ ^y(es)?$ ]]
}

# Print a spinner while a background process runs
# Arguments:
#   $1 - PID to wait for
#   $2 - Message to display
spinner() {
    local pid="$1"
    local msg="$2"
    local spin_chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        printf '\r%s %s ' "${spin_chars:i++%${#spin_chars}:1}" "$msg"
        sleep 0.1
    done
    printf '\r\033[K'
}

# Read a file safely
# Arguments:
#   $1 - File path
# Returns: File contents via stdout, empty if not readable
read_file() {
    local file="$1"
    [[ -r "$file" ]] && cat "$file" 2>/dev/null
}

# Get a value from a key=value file
# Arguments:
#   $1 - File path
#   $2 - Key name
# Returns: Value via stdout
get_config_value() {
    local file="$1"
    local key="$2"

    [[ -r "$file" ]] || return 1
    grep -oP "^${key}=\K.*" "$file" 2>/dev/null | tr -d '"' | head -1
}

# Create a backup of a file
# Arguments:
#   $1 - File path
# Returns: Backup path via stdout
backup_file() {
    local file="$1"
    local backup="${file}.bak.$(date +%Y%m%d%H%M%S)"

    if [[ -f "$file" ]]; then
        cp "$file" "$backup" && echo "$backup"
    fi
}

# Trim whitespace from a string
# Arguments:
#   $1 - String to trim
# Returns: Trimmed string via stdout
trim() {
    local str="$1"
    str="${str#"${str%%[![:space:]]*}"}"
    str="${str%"${str##*[![:space:]]}"}"
    echo "$str"
}

# Convert bytes to human readable format
# Arguments:
#   $1 - Bytes
# Returns: Human readable string
bytes_to_human() {
    local bytes="$1"
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0

    while [[ $bytes -ge 1024 && $unit -lt 4 ]]; do
        bytes=$((bytes / 1024))
        ((unit++))
    done

    echo "${bytes}${units[$unit]}"
}

# Check if a string is a valid integer
# Arguments:
#   $1 - String to check
# Returns: 0 if integer, 1 otherwise
is_integer() {
    [[ "$1" =~ ^-?[0-9]+$ ]]
}

# Check if a string is a valid IP address
# Arguments:
#   $1 - String to check
# Returns: 0 if valid IP, 1 otherwise
is_ip_address() {
    local ip="$1"
    local IFS='.'
    local -a octets
    read -ra octets <<< "$ip"

    [[ ${#octets[@]} -eq 4 ]] || return 1

    for octet in "${octets[@]}"; do
        is_integer "$octet" || return 1
        [[ $octet -ge 0 && $octet -le 255 ]] || return 1
    done

    return 0
}

# Get the script's directory (handles symlinks)
get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    local dir

    while [[ -L "$source" ]]; do
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ "$source" != /* ]] && source="$dir/$source"
    done

    cd -P "$(dirname "$source")" && pwd
}

# Create a temporary file with automatic cleanup
# Arguments:
#   $1 - Prefix (optional)
# Returns: Temp file path
make_temp() {
    local prefix="${1:-suite}"
    local tmpfile
    tmpfile=$(mktemp "/tmp/${prefix}.XXXXXX")
    echo "$tmpfile"
}

# Cleanup function for trap
cleanup() {
    local exit_code=$?
    log_debug "Cleanup called with exit code: $exit_code"
    # Remove any temp files created by the suite
    rm -f /tmp/suite.* 2>/dev/null
    exit $exit_code
}

# Array contains element check
# Arguments:
#   $1 - Element to find
#   $2... - Array elements
# Returns: 0 if found, 1 otherwise
array_contains() {
    local needle="$1"
    shift
    local element

    for element in "$@"; do
        [[ "$element" == "$needle" ]] && return 0
    done
    return 1
}

# Print version information
print_version() {
    echo "$SUITE_NAME v$SUITE_VERSION"
}

# Print help message
print_help() {
    cat << EOF
$SUITE_NAME v$SUITE_VERSION

A comprehensive Linux system optimization and management toolkit.

Usage: $(basename "$0") [OPTIONS]

Options:
  -h, --help        Show this help message
  -v, --version     Show version information
  --no-color        Disable colored output
  --debug           Enable debug logging
  --log-file FILE   Write logs to FILE

Modules:
  optimize          System optimization and tuning
  apps              Application installer
  drivers           Driver management
  recovery          System recovery tools

For more information, see the documentation in docs/
EOF
}
