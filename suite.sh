#!/usr/bin/env bash
#
# Ultimate Linux Suite - Main Launcher
# A comprehensive Linux system optimization and management toolkit
#
# Copyright (c) 2024
# Licensed under MIT License
#

set -euo pipefail

# Determine script directory (handles symlinks)
_get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    local dir

    while [[ -L "$source" ]]; do
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ "$source" != /* ]] && source="$dir/$source"
    done

    cd -P "$(dirname "$source")" && pwd
}

# Suite directory
declare -gr SUITE_DIR="$(_get_script_dir)"

# Source library files
source "$SUITE_DIR/lib/logging.sh"
source "$SUITE_DIR/lib/utils.sh"
source "$SUITE_DIR/lib/os_detect.sh"
source "$SUITE_DIR/lib/hardware_detect.sh"
source "$SUITE_DIR/lib/pkg.sh"
source "$SUITE_DIR/lib/menu.sh"

# Source menu files
source "$SUITE_DIR/menus/main_menu.sh"
source "$SUITE_DIR/menus/optimize_menu.sh"
source "$SUITE_DIR/menus/apps_menu.sh"
source "$SUITE_DIR/menus/drivers_menu.sh"
source "$SUITE_DIR/menus/recovery_menu.sh"

# Source module files
source "$SUITE_DIR/modules/optimize.sh"
source "$SUITE_DIR/modules/apps.sh"
source "$SUITE_DIR/modules/drivers.sh"
source "$SUITE_DIR/modules/recovery.sh"
source "$SUITE_DIR/modules/setup_profiles.sh"

# Global configuration
declare -g SHOW_WELCOME=1
declare -g DEBUG_MODE=0

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                print_help
                exit 0
                ;;
            -v|--version)
                print_version
                exit 0
                ;;
            --no-color)
                disable_colors
                shift
                ;;
            --debug)
                DEBUG_MODE=1
                set_log_level DEBUG
                shift
                ;;
            --log-file)
                if [[ -n "${2:-}" ]]; then
                    LOG_FILE="$2"
                    shift 2
                else
                    echo "Error: --log-file requires a path argument" >&2
                    exit 1
                fi
                ;;
            --no-welcome)
                SHOW_WELCOME=0
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                echo "Use --help for usage information" >&2
                exit 1
                ;;
        esac
    done
}

# Initialize the suite
initialize() {
    # Initialize logging
    local log_file=""
    if [[ -n "${LOG_FILE:-}" ]]; then
        log_file="$LOG_FILE"
    elif [[ $DEBUG_MODE -eq 1 ]]; then
        log_file="/tmp/suite-$(date +%Y%m%d-%H%M%S).log"
    fi

    logging_init "$log_file" "$([[ $DEBUG_MODE -eq 1 ]] && echo 0 || echo 1)"

    log_section "Ultimate Linux Suite"
    log_info "Version: $SUITE_VERSION"
    log_info "Starting initialization..."

    # Detect operating system
    log_info "Detecting operating system..."
    detect_os

    # Detect hardware
    log_info "Detecting hardware..."
    detect_hardware

    # Initialize menu system
    log_info "Initializing menu system..."
    menu_init
    menu_set_title "$SUITE_NAME v$SUITE_VERSION"

    # Load appropriate backend
    log_info "Loading backend..."
    load_backend

    # Initialize modules
    log_info "Initializing modules..."
    init_modules

    log_info "Initialization complete"
    log_debug "OS: $OS_ID ($OS_FAMILY)"
    log_debug "Package Manager: $PKG_MANAGER"
    log_debug "Backend: $(get_backend_name)"
}

# Load the appropriate OS backend
load_backend() {
    local backend_name
    backend_name=$(get_backend_name)
    local backend_file="$SUITE_DIR/backends/${backend_name}.sh"

    if [[ -f "$backend_file" ]]; then
        log_debug "Loading backend: $backend_name"
        source "$backend_file"

        # Initialize the backend
        if declare -f backend_init &>/dev/null; then
            backend_init
        fi
    else
        log_warn "Backend not found: $backend_name, using generic"
        source "$SUITE_DIR/backends/generic.sh"
        backend_init
    fi
}

# Initialize all modules
init_modules() {
    # Initialize optimization module
    if declare -f module_optimize_init &>/dev/null; then
        module_optimize_init
    fi

    # Initialize apps module
    if declare -f module_apps_init &>/dev/null; then
        module_apps_init
    fi

    # Initialize drivers module
    if declare -f module_drivers_init &>/dev/null; then
        module_drivers_init
    fi

    # Initialize recovery module
    if declare -f module_recovery_init &>/dev/null; then
        module_recovery_init
    fi

    # Initialize profiles module
    if declare -f module_profiles_init &>/dev/null; then
        module_profiles_init
    fi
}

# Check system requirements
check_requirements() {
    log_debug "Checking system requirements..."

    # Check for required commands
    local required_cmds=("bash" "cat" "grep" "sed" "awk")
    local missing=()

    for cmd in "${required_cmds[@]}"; do
        if ! have_cmd "$cmd"; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing[*]}"
        exit 1
    fi

    # Check bash version (need 4.0+)
    if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
        log_error "Bash 4.0 or higher required (current: $BASH_VERSION)"
        exit 1
    fi

    log_debug "System requirements satisfied"
    return 0
}

# Main entry point
main() {
    # Parse command line arguments
    parse_args "$@"

    # Check requirements
    check_requirements

    # Initialize the suite
    initialize

    # Set up cleanup trap
    trap cleanup EXIT

    # Show welcome screen if enabled
    if [[ $SHOW_WELCOME -eq 1 ]]; then
        show_welcome_screen
    fi

    # Run main menu
    run_main_menu

    # Cleanup
    log_info "Exiting Ultimate Linux Suite"
    return 0
}

# Run main function
main "$@"
