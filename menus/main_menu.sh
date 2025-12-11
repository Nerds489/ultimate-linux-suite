#!/usr/bin/env bash
#
# main_menu.sh - Main Menu for Ultimate Linux Suite
#
# Provides the top-level navigation menu
#

# Prevent multiple sourcing
[[ -n "${_MAIN_MENU_SH_LOADED:-}" ]] && return 0
readonly _MAIN_MENU_SH_LOADED=1

# Main menu loop
run_main_menu() {
    local choice

    while true; do
        choice=$(menu_select "Main Menu" \
            "Select an option:" \
            "optimize"  "System Optimization" \
            "apps"      "Application Installer" \
            "drivers"   "Driver Manager" \
            "recovery"  "Recovery & Tools" \
            "info"      "System Information" \
            "exit"      "Exit")

        case "$choice" in
            optimize)
                run_optimize_menu
                ;;
            apps)
                run_apps_menu
                ;;
            drivers)
                run_drivers_menu
                ;;
            recovery)
                run_recovery_menu
                ;;
            info)
                show_system_info
                ;;
            exit|"")
                if yes_no_prompt "Exit" "Are you sure you want to exit?"; then
                    log_info "Exiting Ultimate Linux Suite"
                    return 0
                fi
                ;;
        esac
    done
}

# Display system information
show_system_info() {
    local info_text=""

    info_text+="=== Operating System ===\n"
    info_text+="$(print_os_info)\n\n"

    info_text+="=== Hardware ===\n"
    info_text+="$(print_hardware_info)\n\n"

    info_text+="=== Backend ===\n"
    if declare -f backend_print_info &>/dev/null; then
        info_text+="$(backend_print_info)\n"
    else
        info_text+="Backend: Not loaded\n"
    fi

    # Create a temp file for the info
    local tmpfile
    tmpfile=$(make_temp "sysinfo")
    echo -e "$info_text" > "$tmpfile"

    textbox "System Information" "$tmpfile"
    rm -f "$tmpfile"
}

# Quick action menu for common tasks
run_quick_actions() {
    local choice

    choice=$(menu_select "Quick Actions" \
        "Select a quick action:" \
        "update"    "Update System" \
        "clean"     "Clean Package Cache" \
        "info"      "Show System Info" \
        "back"      "Back to Main Menu")

    case "$choice" in
        update)
            show_wait "Updating system..."
            if declare -f backend_system_update &>/dev/null; then
                backend_system_update
            else
                pkg_update
                pkg_upgrade
            fi
            message_box "Update Complete" "System update finished."
            ;;
        clean)
            show_wait "Cleaning package cache..."
            pkg_clean
            message_box "Cleanup Complete" "Package cache cleaned."
            ;;
        info)
            show_system_info
            ;;
        back|"")
            return 0
            ;;
    esac
}

# Welcome screen shown on first launch
show_welcome_screen() {
    local welcome_msg

    welcome_msg="Welcome to Ultimate Linux Suite!

Detected System:
  OS: $(get_os_summary)
  CPU: $(get_cpu_summary)
  RAM: ${TOTAL_RAM_GB}GB
  GPU: $GPU_VENDOR ${GPU_MODEL:-Unknown}
  Form: $FORM_FACTOR

Backend: ${BACKEND_DISPLAY_NAME:-Generic}
Package Manager: $PKG_MANAGER"

    message_box "Welcome" "$welcome_msg"
}

# Show about dialog
show_about() {
    local about_msg

    about_msg="Ultimate Linux Suite v${SUITE_VERSION}

A comprehensive Linux system optimization
and management toolkit.

Features:
  - System Optimization
  - Application Installer
  - Driver Management
  - Recovery Tools

Supports:
  - Debian/Ubuntu family
  - Fedora/RHEL family
  - Arch Linux family
  - openSUSE family
  - Security distributions"

    message_box "About" "$about_msg"
}
