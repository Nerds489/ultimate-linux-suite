#!/usr/bin/env bash
#
# apps_menu.sh - Application Installer Menu for Ultimate Linux Suite
#
# Provides interactive application installation with categories,
# presets, queue management, and smart recommendations.
#

# Prevent multiple sourcing
[[ -n "${_APPS_MENU_SH_LOADED:-}" ]] && return 0
readonly _APPS_MENU_SH_LOADED=1

# ============================================================================
# MAIN APPLICATION INSTALLER MENU
# ============================================================================

run_apps_menu() {
    local choice

    while true; do
        local queue_count
        queue_count=$(queue_size 2>/dev/null || echo "0")

        local queue_label="View/Edit Queue"
        if [[ "$queue_count" -gt 0 ]]; then
            queue_label="View/Edit Queue ($queue_count)"
        fi

        choice=$(menu_select "Application Installer" \
            "browse"     "Browse by Category" \
            "presets"    "Role-Based Presets" \
            "recommend"  "Smart Recommendations" \
            "queue"      "$queue_label" \
            "install"    "Run Installation" \
            "search"     "Search Applications" \
            "flatpak"    "Flatpak Management" \
            "snap"       "Snap Management" \
            "packages"   "Package Manager" \
            "back"       "Back to Main Menu")

        case "$choice" in
            browse)
                run_category_browser
                ;;
            presets)
                run_presets_menu
                ;;
            recommend)
                run_recommendations_menu
                ;;
            queue)
                run_queue_menu
                ;;
            install)
                run_installation
                ;;
            search)
                run_app_search
                ;;
            flatpak)
                run_flatpak_menu
                ;;
            snap)
                run_snap_menu
                ;;
            packages)
                run_packages_menu
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# ============================================================================
# CATEGORY BROWSER
# ============================================================================

run_category_browser() {
    local choice

    while true; do
        # Build category list with app counts
        local menu_args=()
        local cat

        for cat in $(list_categories); do
            local cat_name count
            cat_name=$(get_category_name "$cat")
            count=$(count_apps_in_category "$cat")
            menu_args+=("$cat" "$cat_name ($count apps)")
        done

        menu_args+=("back" "Back")

        choice=$(menu_select "Browse Categories" "${menu_args[@]}")

        case "$choice" in
            back|"")
                return 0
                ;;
            *)
                browse_category "$choice"
                ;;
        esac
    done
}

# Browse apps in a specific category
browse_category() {
    local category="$1"
    local cat_name
    cat_name=$(get_category_name "$category")

    while true; do
        # Build checklist of apps in category
        local checklist_args=()
        local app_id

        for app_id in $(list_apps_in_category "$category"); do
            local app_name status_display desc state
            app_name=$(get_app_name "$app_id")
            desc=$(get_app_description "$app_id")
            status_display=$(get_app_status_display "$app_id")

            # Check if already in queue
            if queue_contains "$app_id" 2>/dev/null; then
                state="on"
            else
                state="off"
            fi

            # Build label with status
            local label="$app_name"
            if [[ -n "$status_display" ]]; then
                label="$app_name $status_display"
            fi

            checklist_args+=("$app_id" "$label" "$state")
        done

        local selected
        selected=$(menu_checklist "$cat_name" \
            "Select apps to add to queue (space to toggle):" \
            "${checklist_args[@]}")

        if [[ -z "$selected" ]]; then
            # User cancelled or selected nothing
            return 0
        fi

        # Clear existing selections for this category from queue
        for app_id in $(list_apps_in_category "$category"); do
            queue_remove "$app_id" 2>/dev/null || true
        done

        # Add selected apps to queue
        local count=0
        for app_id in $selected; do
            queue_add "$app_id"
            ((count++))
        done

        if [[ $count -gt 0 ]]; then
            message_box "Added to Queue" "$count app(s) added to installation queue."
        fi

        return 0
    done
}

# ============================================================================
# PRESETS MENU
# ============================================================================

run_presets_menu() {
    local choice

    while true; do
        # Build presets list with app counts
        local menu_args=()

        # Gaming
        menu_args+=("gaming" "Gaming Setup ($(get_preset_count gaming) apps)")
        menu_args+=("developer" "Developer Workstation ($(get_preset_count developer) apps)")
        menu_args+=("creator" "Content Creator ($(get_preset_count creator) apps)")
        menu_args+=("minimal" "Minimal Lightweight ($(get_preset_count minimal) apps)")
        menu_args+=("office" "Office Suite ($(get_preset_count office) apps)")
        menu_args+=("security" "Security Tools ($(get_preset_count security) apps)")
        menu_args+=("communication" "Communication ($(get_preset_count communication) apps)")
        menu_args+=("media" "Media & Entertainment ($(get_preset_count media) apps)")
        menu_args+=("back" "Back")

        choice=$(menu_select "Application Presets" \
            "Select a preset to load:" \
            "${menu_args[@]}")

        case "$choice" in
            back|"")
                return 0
                ;;
            *)
                load_preset_interactive "$choice"
                ;;
        esac
    done
}

# Load preset interactively
load_preset_interactive() {
    local preset="$1"
    local packages
    packages=$(get_preset_packages "$preset")

    if [[ -z "$packages" ]]; then
        message_box "Error" "Unknown preset: $preset"
        return 1
    fi

    # Build info message
    local info_msg="Preset: $preset\n\nApplications:\n"
    local app
    for app in $packages; do
        local app_name status
        app_name=$(get_app_name "$app" 2>/dev/null || echo "$app")
        status=$(get_app_status_display "$app" 2>/dev/null || echo "")
        info_msg+="  - $app_name $status\n"
    done

    info_msg+="\nLoad this preset into the installation queue?"

    if yes_no_prompt "Load Preset" "$info_msg"; then
        queue_load_preset "$preset"
        local queue_count
        queue_count=$(queue_size)
        message_box "Preset Loaded" "Preset '$preset' loaded.\nQueue now contains $queue_count app(s)."
    fi
}

# ============================================================================
# SMART RECOMMENDATIONS
# ============================================================================

run_recommendations_menu() {
    # Get hardware-based recommendation
    local recommended_preset
    recommended_preset=$(get_recommended_preset 2>/dev/null || echo "minimal")

    local info_msg="Based on your system hardware:\n\n"
    info_msg+="  CPU: ${CPU_MODEL:-Unknown} (${CPU_CORES:-?} cores)\n"
    info_msg+="  RAM: ${TOTAL_RAM_GB:-?}GB\n"
    info_msg+="  GPU: ${GPU_VENDOR:-Unknown} ${GPU_MODEL:-}\n"
    info_msg+="  Type: ${FORM_FACTOR:-Unknown}\n\n"
    info_msg+="Recommended preset: $recommended_preset\n\n"

    local choice
    choice=$(menu_select "Smart Recommendations" \
        "$info_msg" \
        "load"       "Load Recommended ($recommended_preset)" \
        "customize"  "Customize Selection" \
        "view"       "View Recommendations" \
        "back"       "Back")

    case "$choice" in
        load)
            queue_load_preset "$recommended_preset"
            local queue_count
            queue_count=$(queue_size)
            message_box "Preset Loaded" "Recommended preset loaded.\nQueue contains $queue_count app(s)."
            ;;
        customize)
            customize_recommendations
            ;;
        view)
            view_recommendations
            ;;
    esac
}

# View detailed recommendations
view_recommendations() {
    local tmpfile
    tmpfile=$(make_temp "recommendations")

    {
        echo "=== System Analysis ==="
        echo ""
        echo "Hardware:"
        echo "  CPU: ${CPU_MODEL:-Unknown}"
        echo "  Cores: ${CPU_CORES:-?}"
        echo "  RAM: ${TOTAL_RAM_GB:-?}GB (${TOTAL_RAM_MB:-?}MB)"
        echo "  GPU: ${GPU_VENDOR:-Unknown} ${GPU_MODEL:-}"
        echo "  Form Factor: ${FORM_FACTOR:-Unknown}"
        echo ""
        echo "=== Recommended Applications ==="
        echo ""

        local app
        for app in $(get_recommended_apps); do
            local app_name desc
            app_name=$(get_app_name "$app" 2>/dev/null || echo "$app")
            desc=$(get_app_description "$app" 2>/dev/null || echo "")
            echo "  - $app_name: $desc"
        done

        echo ""
        echo "=== Recommended Preset ==="
        echo ""
        local preset
        preset=$(get_recommended_preset)
        echo "  Preset: $preset"
        echo "  Apps: $(get_preset_packages "$preset")"
    } > "$tmpfile"

    textbox "Recommendations" "$tmpfile"
    rm -f "$tmpfile"
}

# Customize recommendation selection
customize_recommendations() {
    local apps
    # shellcheck disable=SC2207
    apps=($(get_recommended_apps))

    if [[ ${#apps[@]} -eq 0 ]]; then
        message_box "No Recommendations" "No specific recommendations for your hardware."
        return
    fi

    # Build checklist
    local checklist_args=()
    local app
    for app in "${apps[@]}"; do
        local app_name status_display
        app_name=$(get_app_name "$app" 2>/dev/null || echo "$app")
        status_display=$(get_app_status_display "$app" 2>/dev/null || echo "")
        checklist_args+=("$app" "$app_name $status_display" "on")
    done

    local selected
    selected=$(menu_checklist "Customize Recommendations" \
        "Select apps to install:" \
        "${checklist_args[@]}")

    if [[ -n "$selected" ]]; then
        for app in $selected; do
            queue_add "$app"
        done

        local count
        # shellcheck disable=SC2086
        set -- $selected
        count=$#
        message_box "Added to Queue" "$count app(s) added to installation queue."
    fi
}

# ============================================================================
# QUEUE MANAGEMENT
# ============================================================================

run_queue_menu() {
    while true; do
        local queue_count
        queue_count=$(queue_size)

        if [[ "$queue_count" -eq 0 ]]; then
            message_box "Queue Empty" "The installation queue is empty.\n\nUse 'Browse by Category' or 'Presets' to add applications."
            return 0
        fi

        local choice
        choice=$(menu_select "Installation Queue ($queue_count apps)" \
            "view"    "View Queue Contents" \
            "remove"  "Remove from Queue" \
            "clear"   "Clear Queue" \
            "install" "Run Installation" \
            "back"    "Back")

        case "$choice" in
            view)
                view_queue
                ;;
            remove)
                remove_from_queue_interactive
                ;;
            clear)
                clear_queue_interactive
                ;;
            install)
                run_installation
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# View queue contents
view_queue() {
    local tmpfile
    tmpfile=$(make_temp "queue")

    {
        echo "=== Installation Queue ==="
        echo ""

        local idx=1
        local app_id
        for app_id in $(queue_list); do
            local app_name desc method
            app_name=$(get_app_name "$app_id")
            desc=$(get_app_description "$app_id")
            method=$(get_app_method "$app_id")

            echo "$idx. $app_name"
            echo "   ID: $app_id"
            echo "   Description: $desc"
            echo "   Install via: $method"
            echo ""
            ((idx++))
        done

        echo "=== Total: $(queue_size) app(s) ==="
    } > "$tmpfile"

    textbox "Queue Contents" "$tmpfile"
    rm -f "$tmpfile"
}

# Remove apps from queue interactively
remove_from_queue_interactive() {
    local queue_count
    queue_count=$(queue_size)

    if [[ "$queue_count" -eq 0 ]]; then
        message_box "Queue Empty" "Nothing to remove."
        return
    fi

    # Build checklist of queued apps
    local checklist_args=()
    local app_id
    for app_id in $(queue_list); do
        local app_name
        app_name=$(get_app_name "$app_id")
        checklist_args+=("$app_id" "$app_name" "off")
    done

    local selected
    selected=$(menu_checklist "Remove from Queue" \
        "Select apps to remove:" \
        "${checklist_args[@]}")

    if [[ -n "$selected" ]]; then
        local count=0
        for app_id in $selected; do
            queue_remove "$app_id"
            ((count++))
        done
        message_box "Removed" "$count app(s) removed from queue."
    fi
}

# Clear queue with confirmation
clear_queue_interactive() {
    local queue_count
    queue_count=$(queue_size)

    if yes_no_prompt "Clear Queue" "Remove all $queue_count app(s) from the queue?"; then
        queue_clear
        message_box "Cleared" "Installation queue has been cleared."
    fi
}

# ============================================================================
# INSTALLATION
# ============================================================================

run_installation() {
    local queue_count
    queue_count=$(queue_size)

    if [[ "$queue_count" -eq 0 ]]; then
        message_box "Queue Empty" "Nothing to install.\n\nAdd applications using 'Browse by Category' or 'Presets'."
        return
    fi

    # Build summary
    local summary="Ready to install $queue_count application(s):\n\n"
    local native_count=0
    local flatpak_count=0
    local app_id

    for app_id in $(queue_list); do
        local app_name method
        app_name=$(get_app_name "$app_id")
        method=$(get_app_method "$app_id")
        summary+="  - $app_name ($method)\n"

        if [[ "$method" == "flatpak" ]]; then
            ((flatpak_count++))
        else
            ((native_count++))
        fi
    done

    summary+="\nNative packages: $native_count\n"
    summary+="Flatpak apps: $flatpak_count\n"
    summary+="\nProceed with installation?"

    if ! yes_no_prompt "Confirm Installation" "$summary"; then
        return
    fi

    # Check root access
    if ! is_root && ! have_cmd sudo; then
        message_box "Error" "Root access required for installation.\nPlease run with sudo."
        return 1
    fi

    # Run installation
    show_wait "Installing applications..."
    log_info "Starting installation of $queue_count apps"

    install_queue

    # Show results
    local result_msg
    result_msg=$(get_install_summary)
    message_box "Installation Complete" "$result_msg"
}

# ============================================================================
# APPLICATION SEARCH
# ============================================================================

run_app_search() {
    local term
    term=$(input_box "Search Applications" "Enter search term:")

    if [[ -z "$term" ]]; then
        return
    fi

    local results
    # shellcheck disable=SC2207
    results=($(search_apps "$term"))

    if [[ ${#results[@]} -eq 0 ]]; then
        message_box "No Results" "No applications found matching '$term'."
        return
    fi

    # Build checklist of results
    local checklist_args=()
    local app_id
    for app_id in "${results[@]}"; do
        local app_name desc status_display
        app_name=$(get_app_name "$app_id")
        desc=$(get_app_description "$app_id")
        status_display=$(get_app_status_display "$app_id")
        checklist_args+=("$app_id" "$app_name $status_display" "off")
    done

    local selected
    selected=$(menu_checklist "Search Results: $term" \
        "Found ${#results[@]} app(s). Select to add to queue:" \
        "${checklist_args[@]}")

    if [[ -n "$selected" ]]; then
        local count=0
        for app_id in $selected; do
            queue_add "$app_id"
            ((count++))
        done
        message_box "Added to Queue" "$count app(s) added to installation queue."
    fi
}

# ============================================================================
# FLATPAK MANAGEMENT
# ============================================================================

run_flatpak_menu() {
    # Check Flatpak availability
    if [[ "$FLATPAK_AVAILABLE" -eq 0 ]]; then
        if yes_no_prompt "Flatpak Not Installed" "Flatpak is not installed.\n\nInstall Flatpak now?"; then
            show_wait "Installing Flatpak..."
            flatpak_init
            message_box "Flatpak Installed" "Flatpak has been installed.\nYou may need to log out and back in."
        fi
        return
    fi

    while true; do
        local choice
        choice=$(menu_select "Flatpak Management" \
            "list"     "List Installed Apps" \
            "update"   "Update All Apps" \
            "search"   "Search Flathub" \
            "install"  "Install by ID" \
            "remove"   "Remove App" \
            "setup"    "Setup Flathub" \
            "back"     "Back")

        case "$choice" in
            list)
                flatpak_list_interactive
                ;;
            update)
                flatpak_update_interactive
                ;;
            search)
                flatpak_search_interactive
                ;;
            install)
                flatpak_install_interactive
                ;;
            remove)
                flatpak_remove_interactive
                ;;
            setup)
                flatpak_setup_interactive
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

flatpak_list_interactive() {
    local tmpfile
    tmpfile=$(make_temp "flatpaks")

    flatpak_list > "$tmpfile" 2>&1

    if [[ ! -s "$tmpfile" ]]; then
        echo "No Flatpak apps installed." > "$tmpfile"
    fi

    textbox "Installed Flatpak Apps" "$tmpfile"
    rm -f "$tmpfile"
}

flatpak_update_interactive() {
    if yes_no_prompt "Update Flatpaks" "Update all Flatpak applications?"; then
        show_wait "Updating Flatpak apps..."
        flatpak_update
        message_box "Update Complete" "All Flatpak applications have been updated."
    fi
}

flatpak_search_interactive() {
    local term
    term=$(input_box "Search Flathub" "Enter search term:")

    if [[ -z "$term" ]]; then
        return
    fi

    local tmpfile
    tmpfile=$(make_temp "flatpak_search")

    flatpak_search "$term" > "$tmpfile" 2>&1

    if [[ ! -s "$tmpfile" ]]; then
        echo "No results found for '$term'." > "$tmpfile"
    fi

    textbox "Flathub Search: $term" "$tmpfile"
    rm -f "$tmpfile"
}

flatpak_install_interactive() {
    local app_id
    app_id=$(input_box "Install Flatpak" "Enter Flatpak application ID:\n(e.g., org.gimp.GIMP)")

    if [[ -z "$app_id" ]]; then
        return
    fi

    if yes_no_prompt "Confirm" "Install Flatpak: $app_id?"; then
        show_wait "Installing $app_id..."
        if flatpak install -y flathub "$app_id" 2>&1; then
            message_box "Success" "Flatpak app installed successfully."
        else
            message_box "Error" "Failed to install Flatpak app."
        fi
    fi
}

flatpak_remove_interactive() {
    local app_id
    app_id=$(input_box "Remove Flatpak" "Enter Flatpak application ID to remove:")

    if [[ -z "$app_id" ]]; then
        return
    fi

    if yes_no_prompt "Confirm Removal" "Remove Flatpak: $app_id?\n\nThis cannot be undone."; then
        show_wait "Removing $app_id..."
        if flatpak uninstall -y "$app_id" 2>&1; then
            message_box "Success" "Flatpak app removed."
        else
            message_box "Error" "Failed to remove Flatpak app."
        fi
    fi
}

flatpak_setup_interactive() {
    if [[ "$FLATHUB_CONFIGURED" -eq 1 ]]; then
        message_box "Already Configured" "Flathub is already configured."
        return
    fi

    if yes_no_prompt "Setup Flathub" "Add Flathub repository?\n\nThis allows installing apps from the Flathub store."; then
        show_wait "Adding Flathub..."
        flatpak_init
        message_box "Success" "Flathub repository added.\nYou may need to log out and back in."
    fi
}

# ============================================================================
# SNAP MANAGEMENT
# ============================================================================

run_snap_menu() {
    # Check Snap availability
    if [[ "$SNAP_AVAILABLE" -eq 0 ]]; then
        if yes_no_prompt "Snap Not Available" "Snap is not installed or not running.\n\nInstall and enable Snap?"; then
            show_wait "Installing Snap..."
            snap_init
            message_box "Snap Installed" "Snap has been installed.\nA reboot may be required."
        fi
        return
    fi

    while true; do
        local status_msg
        if [[ "$SNAP_ENABLED" -eq 1 ]]; then
            status_msg="(enabled)"
        else
            status_msg="(disabled)"
        fi

        local choice
        choice=$(menu_select "Snap Management $status_msg" \
            "toggle"   "Enable/Disable Snap Support" \
            "list"     "List Installed Snaps" \
            "update"   "Update All Snaps" \
            "install"  "Install Snap" \
            "remove"   "Remove Snap" \
            "back"     "Back")

        case "$choice" in
            toggle)
                snap_toggle_interactive
                ;;
            list)
                snap_list_interactive
                ;;
            update)
                snap_update_interactive
                ;;
            install)
                snap_install_interactive
                ;;
            remove)
                snap_remove_interactive
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

snap_toggle_interactive() {
    if [[ "$SNAP_ENABLED" -eq 1 ]]; then
        snap_disable
        message_box "Snap Disabled" "Snap support has been disabled.\n\nApps will be installed via native packages or Flatpak instead."
    else
        snap_enable
        message_box "Snap Enabled" "Snap support has been enabled.\n\nSnap apps can now be installed."
    fi
}

snap_list_interactive() {
    local tmpfile
    tmpfile=$(make_temp "snaps")

    snap_list > "$tmpfile" 2>&1

    if [[ ! -s "$tmpfile" ]]; then
        echo "No Snap apps installed." > "$tmpfile"
    fi

    textbox "Installed Snaps" "$tmpfile"
    rm -f "$tmpfile"
}

snap_update_interactive() {
    if yes_no_prompt "Update Snaps" "Update all Snap applications?"; then
        show_wait "Updating Snap apps..."
        snap_update
        message_box "Update Complete" "All Snap applications have been updated."
    fi
}

snap_install_interactive() {
    if [[ "$SNAP_ENABLED" -eq 0 ]]; then
        message_box "Snap Disabled" "Snap support is currently disabled.\n\nEnable it first."
        return
    fi

    local snap_name
    snap_name=$(input_box "Install Snap" "Enter Snap package name:")

    if [[ -z "$snap_name" ]]; then
        return
    fi

    if yes_no_prompt "Confirm" "Install Snap: $snap_name?"; then
        show_wait "Installing $snap_name..."
        if snap_install "$snap_name" 2>&1; then
            message_box "Success" "Snap installed successfully."
        else
            message_box "Error" "Failed to install Snap."
        fi
    fi
}

snap_remove_interactive() {
    local snap_name
    snap_name=$(input_box "Remove Snap" "Enter Snap package name to remove:")

    if [[ -z "$snap_name" ]]; then
        return
    fi

    if yes_no_prompt "Confirm Removal" "Remove Snap: $snap_name?\n\nThis cannot be undone."; then
        show_wait "Removing $snap_name..."
        if snap_remove "$snap_name" 2>&1; then
            message_box "Success" "Snap removed."
        else
            message_box "Error" "Failed to remove Snap."
        fi
    fi
}

# ============================================================================
# PACKAGE MANAGER OPERATIONS
# ============================================================================

run_packages_menu() {
    while true; do
        local choice
        choice=$(menu_select "Package Manager" \
            "update"  "Update Package Index" \
            "upgrade" "Upgrade All Packages" \
            "search"  "Search Packages" \
            "install" "Install Package" \
            "remove"  "Remove Package" \
            "clean"   "Clean Cache" \
            "info"    "System Info" \
            "back"    "Back")

        case "$choice" in
            update)
                pkg_update_interactive
                ;;
            upgrade)
                pkg_upgrade_interactive
                ;;
            search)
                pkg_search_interactive
                ;;
            install)
                pkg_install_interactive
                ;;
            remove)
                pkg_remove_interactive
                ;;
            clean)
                pkg_clean_interactive
                ;;
            info)
                pkg_info_interactive
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

pkg_update_interactive() {
    show_wait "Updating package indexes..."
    pkg_update_indexes
    message_box "Complete" "Package indexes updated."
}

pkg_upgrade_interactive() {
    if yes_no_prompt "Upgrade Packages" "Upgrade all system packages?\n\nThis may take some time."; then
        show_wait "Upgrading packages..."
        pkg_upgrade
        message_box "Complete" "Package upgrade finished."
    fi
}

pkg_search_interactive() {
    local term
    term=$(input_box "Search Packages" "Enter search term:")

    if [[ -z "$term" ]]; then
        return
    fi

    local tmpfile
    tmpfile=$(make_temp "pkg_search")

    show_wait "Searching for: $term"
    pkg_search "$term" > "$tmpfile" 2>&1

    if [[ ! -s "$tmpfile" ]]; then
        echo "No packages found matching '$term'." > "$tmpfile"
    fi

    textbox "Package Search: $term" "$tmpfile"
    rm -f "$tmpfile"
}

pkg_install_interactive() {
    local pkg
    pkg=$(input_box "Install Package" "Enter package name to install:")

    if [[ -z "$pkg" ]]; then
        return
    fi

    if yes_no_prompt "Confirm" "Install package: $pkg?"; then
        show_wait "Installing $pkg..."
        if pkg_install "$pkg"; then
            message_box "Success" "Package '$pkg' installed."
        else
            message_box "Error" "Failed to install '$pkg'."
        fi
    fi
}

pkg_remove_interactive() {
    local pkg
    pkg=$(input_box "Remove Package" "Enter package name to remove:")

    if [[ -z "$pkg" ]]; then
        return
    fi

    if yes_no_prompt "Confirm Removal" "Remove package: $pkg?\n\nThis cannot be undone."; then
        show_wait "Removing $pkg..."
        if pkg_remove "$pkg"; then
            message_box "Success" "Package '$pkg' removed."
        else
            message_box "Error" "Failed to remove '$pkg'."
        fi
    fi
}

pkg_clean_interactive() {
    if yes_no_prompt "Clean Cache" "Clean package cache and remove unused packages?"; then
        show_wait "Cleaning..."
        pkg_clean
        message_box "Complete" "Package cache cleaned."
    fi
}

pkg_info_interactive() {
    local tmpfile
    tmpfile=$(make_temp "pkg_info")

    {
        echo "=== Package System Information ==="
        echo ""
        print_pkg_info
        echo ""
        echo "=== Distribution ==="
        echo ""
        print_os_info 2>/dev/null || echo "OS info not available"
    } > "$tmpfile"

    textbox "Package System Info" "$tmpfile"
    rm -f "$tmpfile"
}
