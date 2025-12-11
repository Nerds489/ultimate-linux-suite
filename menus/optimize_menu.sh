#!/usr/bin/env bash
#
# optimize_menu.sh - Optimization Menu for Ultimate Linux Suite
#
# Provides system optimization menus with Auto and Manual Expert modes
#

# Prevent multiple sourcing
[[ -n "${_OPTIMIZE_MENU_SH_LOADED:-}" ]] && return 0
readonly _OPTIMIZE_MENU_SH_LOADED=1

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN OPTIMIZATION MENU
# ═══════════════════════════════════════════════════════════════════════════════

# Main optimization menu loop
run_optimize_menu() {
    local choice

    while true; do
        choice=$(menu_select "System Optimization" \
            "Select optimization mode:" \
            "auto"     "Auto-Optimize (Recommended)" \
            "manual"   "Manual Expert Mode" \
            "profiles" "Quick Profiles" \
            "view"     "View Current State" \
            "reset"    "Reset to Defaults" \
            "back"     "Back to Main Menu")

        case "$choice" in
            auto)
                run_auto_optimize
                ;;
            manual)
                run_manual_expert_menu
                ;;
            profiles)
                run_quick_profiles_menu
                ;;
            view)
                view_optimization_state
                ;;
            reset)
                reset_optimizations
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# VIEW CURRENT STATE
# ═══════════════════════════════════════════════════════════════════════════════

# Display current optimization state
view_optimization_state() {
    local state
    state=$(get_current_optimization_state)

    local tmpfile
    tmpfile=$(mktemp)
    echo -e "$state" > "$tmpfile"

    textbox "Current Optimization State" "$tmpfile"
    rm -f "$tmpfile"
}

# ═══════════════════════════════════════════════════════════════════════════════
# QUICK PROFILES MENU
# ═══════════════════════════════════════════════════════════════════════════════

# Quick optimization profiles
run_quick_profiles_menu() {
    local choice

    choice=$(menu_select "Quick Profiles" \
        "Select a profile to apply:" \
        "desktop"     "Desktop (Balanced)" \
        "gaming"      "Gaming (Performance)" \
        "server"      "Server (Throughput)" \
        "laptop"      "Laptop (Battery)" \
        "workstation" "Workstation (Productivity)" \
        "minimal"     "Minimal (Low Resources)" \
        "back"        "Back")

    case "$choice" in
        desktop|gaming|server|laptop|workstation|minimal)
            if yes_no_prompt "Apply Profile" "Apply the '$choice' optimization profile?\n\nThis will modify system settings."; then
                show_wait "Applying $choice profile..."
                module_apply_profile "$choice"
                message_box "Profile Applied" "The '$choice' profile has been applied.\n\nA reboot is recommended."
            fi
            ;;
        back|"")
            return 0
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# MANUAL EXPERT MODE MENU
# ═══════════════════════════════════════════════════════════════════════════════

# Manual expert mode main menu
run_manual_expert_menu() {
    local choice

    while true; do
        choice=$(menu_select "Manual Expert Mode" \
            "Select category to configure:" \
            "memory"   "Memory Settings" \
            "cpu"      "CPU Settings" \
            "io"       "I/O & Storage" \
            "network"  "Network Optimization" \
            "desktop"  "Desktop Environment" \
            "save"     "Save Configuration" \
            "back"     "Back")

        case "$choice" in
            memory)
                run_memory_settings_menu
                ;;
            cpu)
                run_cpu_settings_menu
                ;;
            io)
                run_io_settings_menu
                ;;
            network)
                run_network_settings_menu
                ;;
            desktop)
                run_desktop_settings_menu
                ;;
            save)
                save_manual_config
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# MEMORY SETTINGS MENU
# ═══════════════════════════════════════════════════════════════════════════════

# Memory settings submenu
run_memory_settings_menu() {
    local choice

    while true; do
        local current_swap
        current_swap=$(get_sysctl_value "vm.swappiness")
        local current_dirty
        current_dirty=$(get_sysctl_value "vm.dirty_ratio")
        local current_dirty_bg
        current_dirty_bg=$(get_sysctl_value "vm.dirty_background_ratio")
        local current_vfs
        current_vfs=$(get_sysctl_value "vm.vfs_cache_pressure")
        local current_min_free
        current_min_free=$(get_sysctl_value "vm.min_free_kbytes")
        local zram_status
        zram_status=$(get_zram_status)

        choice=$(menu_select "Memory Settings" \
            "Current: swap=$current_swap, dirty=$current_dirty" \
            "swappiness"     "Swappiness (current: $current_swap)" \
            "dirty_ratio"    "Dirty Ratio (current: $current_dirty)" \
            "dirty_bg"       "Dirty Background Ratio (current: $current_dirty_bg)" \
            "vfs_pressure"   "VFS Cache Pressure (current: $current_vfs)" \
            "min_free"       "Min Free KB (current: $current_min_free)" \
            "zram"           "ZRAM Configuration ($zram_status)" \
            "back"           "Back")

        case "$choice" in
            swappiness)
                configure_swappiness_interactive
                ;;
            dirty_ratio)
                configure_dirty_ratio_interactive
                ;;
            dirty_bg)
                configure_dirty_bg_interactive
                ;;
            vfs_pressure)
                configure_vfs_pressure_interactive
                ;;
            min_free)
                configure_min_free_interactive
                ;;
            zram)
                configure_zram_interactive
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# Configure swappiness interactively
configure_swappiness_interactive() {
    local current
    current=$(get_sysctl_value "vm.swappiness")

    local help_text="Swappiness controls how aggressively the kernel swaps memory pages.

Values:
  0-10  : Minimal swapping (good for high RAM systems)
  20-40 : Low swapping (recommended for gaming/desktop)
  50-70 : Balanced (default Linux behavior)
  80-100: Aggressive swapping (for low RAM systems)

Current value: $current
Recommended: 10-60 depending on RAM"

    message_box "Swappiness Help" "$help_text"

    local new_value
    new_value=$(input_box "Set Swappiness" "Enter value (0-100):" "$current")

    if [[ -n "$new_value" ]]; then
        if manual_set_swappiness "$new_value"; then
            message_box "Success" "Swappiness set to $new_value"
        else
            message_box "Error" "Failed to set swappiness. Value must be 0-100."
        fi
    fi
}

# Configure dirty_ratio interactively
configure_dirty_ratio_interactive() {
    local current
    current=$(get_sysctl_value "vm.dirty_ratio")

    local help_text="Dirty ratio is the percentage of total memory that can be filled with dirty pages before processes must write them out.

Lower values: More frequent disk writes, less data loss risk
Higher values: Better performance, more RAM for caching

Current value: $current
Recommended: 10-40"

    message_box "Dirty Ratio Help" "$help_text"

    local new_value
    new_value=$(input_box "Set Dirty Ratio" "Enter value (1-100):" "$current")

    if [[ -n "$new_value" ]]; then
        if manual_set_dirty_ratio "$new_value"; then
            message_box "Success" "Dirty ratio set to $new_value"
        else
            message_box "Error" "Failed to set dirty ratio. Value must be 1-100."
        fi
    fi
}

# Configure dirty_background_ratio interactively
configure_dirty_bg_interactive() {
    local current
    current=$(get_sysctl_value "vm.dirty_background_ratio")

    local help_text="Dirty background ratio is the percentage of total memory at which background writeback begins.

This should be lower than dirty_ratio.

Current value: $current
Recommended: 5-15"

    message_box "Dirty Background Ratio Help" "$help_text"

    local new_value
    new_value=$(input_box "Set Dirty Background Ratio" "Enter value (1-100):" "$current")

    if [[ -n "$new_value" ]]; then
        if manual_set_dirty_bg_ratio "$new_value"; then
            message_box "Success" "Dirty background ratio set to $new_value"
        else
            message_box "Error" "Failed to set value. Must be 1-100."
        fi
    fi
}

# Configure VFS cache pressure interactively
configure_vfs_pressure_interactive() {
    local current
    current=$(get_sysctl_value "vm.vfs_cache_pressure")

    local help_text="VFS cache pressure controls the tendency to reclaim memory used for caching directory and inode objects.

Lower values (10-50): Keep directory/inode caches longer
Default (100): Balanced behavior
Higher values (150-200): Reclaim caches more aggressively

Current value: $current
Recommended: 50-150"

    message_box "VFS Cache Pressure Help" "$help_text"

    local new_value
    new_value=$(input_box "Set VFS Cache Pressure" "Enter value (0-500):" "$current")

    if [[ -n "$new_value" ]]; then
        if manual_set_vfs_cache_pressure "$new_value"; then
            message_box "Success" "VFS cache pressure set to $new_value"
        else
            message_box "Error" "Failed to set value. Must be 0-500."
        fi
    fi
}

# Configure min_free_kbytes interactively
configure_min_free_interactive() {
    local current
    current=$(get_sysctl_value "vm.min_free_kbytes")
    local max_value=$((TOTAL_RAM_KB / 4))

    local help_text="Min free kbytes is the minimum amount of memory kept free by the kernel.

Too low: Risk of OOM situations
Too high: Wastes memory

Current value: $current KB
Maximum allowed: $max_value KB (25% of RAM)
Recommended: ${TOTAL_RAM_KB}/32 to ${TOTAL_RAM_KB}/64"

    message_box "Min Free Kbytes Help" "$help_text"

    local new_value
    new_value=$(input_box "Set Min Free Kbytes" "Enter value (1024-$max_value):" "$current")

    if [[ -n "$new_value" ]]; then
        if manual_set_min_free_kb "$new_value"; then
            message_box "Success" "Min free kbytes set to $new_value"
        else
            message_box "Error" "Failed to set value. Must be 1024-$max_value."
        fi
    fi
}

# Configure ZRAM interactively
configure_zram_interactive() {
    local zram_status
    zram_status=$(get_zram_status)

    local choice

    if [[ "$zram_status" == "disabled" ]]; then
        choice=$(menu_select "ZRAM Configuration" \
            "ZRAM is currently disabled" \
            "enable"  "Enable ZRAM" \
            "back"    "Back")

        if [[ "$choice" == "enable" ]]; then
            local default_size=$((TOTAL_RAM_MB / 2))
            local size
            size=$(input_box "ZRAM Size" "Enter ZRAM size in MB:" "$default_size")

            if [[ -n "$size" ]] && [[ "$size" =~ ^[0-9]+$ ]]; then
                show_wait "Configuring ZRAM..."
                if configure_zram "$size"; then
                    message_box "Success" "ZRAM enabled with ${size}MB"
                else
                    message_box "Error" "Failed to configure ZRAM"
                fi
            fi
        fi
    else
        choice=$(menu_select "ZRAM Configuration" \
            "ZRAM is currently $zram_status" \
            "resize"   "Resize ZRAM" \
            "disable"  "Disable ZRAM" \
            "back"     "Back")

        case "$choice" in
            resize)
                local default_size=$((TOTAL_RAM_MB / 2))
                local size
                size=$(input_box "ZRAM Size" "Enter new ZRAM size in MB:" "$default_size")

                if [[ -n "$size" ]] && [[ "$size" =~ ^[0-9]+$ ]]; then
                    show_wait "Resizing ZRAM..."
                    disable_zram
                    if configure_zram "$size"; then
                        message_box "Success" "ZRAM resized to ${size}MB"
                    else
                        message_box "Error" "Failed to resize ZRAM"
                    fi
                fi
                ;;
            disable)
                if yes_no_prompt "Disable ZRAM" "Are you sure you want to disable ZRAM?"; then
                    disable_zram
                    message_box "Success" "ZRAM disabled"
                fi
                ;;
        esac
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# CPU SETTINGS MENU
# ═══════════════════════════════════════════════════════════════════════════════

# CPU settings submenu
run_cpu_settings_menu() {
    local choice

    while true; do
        local current_gov
        current_gov=$(get_cpu_governor)
        local turbo_status
        turbo_status=$(get_turbo_status)

        choice=$(menu_select "CPU Settings" \
            "Governor: $current_gov | Turbo: $turbo_status" \
            "governor"  "CPU Governor (current: $current_gov)" \
            "turbo"     "Turbo Boost ($turbo_status)" \
            "info"      "CPU Information" \
            "back"      "Back")

        case "$choice" in
            governor)
                configure_governor_interactive
                ;;
            turbo)
                configure_turbo_interactive
                ;;
            info)
                show_cpu_info
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# Configure CPU governor interactively
configure_governor_interactive() {
    local current_gov
    current_gov=$(get_cpu_governor)
    local available
    available=$(get_available_governors)

    if [[ "$available" == "none" ]]; then
        message_box "Not Available" "CPU frequency scaling is not available on this system."
        return 0
    fi

    # Build menu items from available governors
    local menu_items=()
    local desc

    for gov in $available; do
        case "$gov" in
            performance)  desc="Maximum performance (high power)" ;;
            powersave)    desc="Minimum frequency (battery saving)" ;;
            schedutil)    desc="Scheduler-driven (recommended)" ;;
            ondemand)     desc="Scale based on load" ;;
            conservative) desc="Gradual frequency scaling" ;;
            userspace)    desc="Manual frequency control" ;;
            *)            desc="$gov governor" ;;
        esac

        if [[ "$gov" == "$current_gov" ]]; then
            desc="$desc [CURRENT]"
        fi

        menu_items+=("$gov" "$desc")
    done

    local choice
    choice=$(menu_select "Select CPU Governor" \
        "Current: $current_gov" \
        "${menu_items[@]}" \
        "back" "Cancel")

    if [[ -n "$choice" ]] && [[ "$choice" != "back" ]]; then
        show_wait "Setting governor to $choice..."
        if apply_cpu_governor "$choice"; then
            message_box "Success" "CPU governor set to $choice"
        else
            message_box "Error" "Failed to set CPU governor"
        fi
    fi
}

# Configure turbo boost interactively
configure_turbo_interactive() {
    local current_status
    current_status=$(get_turbo_status)

    if [[ "$current_status" == "unavailable" ]]; then
        message_box "Not Available" "Turbo boost control is not available on this system."
        return 0
    fi

    local help_text="Turbo Boost allows the CPU to run above its base frequency when thermal and power conditions allow.

Current status: $current_status

Enabling increases performance but uses more power.
Disabling can reduce heat and improve battery life."

    message_box "Turbo Boost" "$help_text"

    local choice
    if [[ "$current_status" == "enabled" ]]; then
        if yes_no_prompt "Turbo Boost" "Turbo boost is enabled. Disable it?"; then
            toggle_turbo_boost 0
            message_box "Success" "Turbo boost disabled"
        fi
    else
        if yes_no_prompt "Turbo Boost" "Turbo boost is disabled. Enable it?"; then
            toggle_turbo_boost 1
            message_box "Success" "Turbo boost enabled"
        fi
    fi
}

# Show CPU information
show_cpu_info() {
    local info=""
    info+="CPU Information\n"
    info+="═══════════════════════════════════════\n\n"
    info+="Vendor: ${CPU_VENDOR:-Unknown}\n"
    info+="Model: ${CPU_MODEL:-Unknown}\n"
    info+="Cores: ${CPU_CORES:-?}\n"
    info+="Threads: ${CPU_THREADS:-?}\n\n"
    info+="Features:\n"
    info+="  Virtualization: $(has_virtualization && echo 'Yes' || echo 'No')\n"
    info+="  AES-NI: $(has_aes && echo 'Yes' || echo 'No')\n"
    info+="  AVX: $(has_avx && echo 'Yes' || echo 'No')\n\n"
    info+="Current Settings:\n"
    info+="  Governor: $(get_cpu_governor)\n"
    info+="  Turbo: $(get_turbo_status)\n"
    info+="  Available Governors: $(get_available_governors)\n"

    local tmpfile
    tmpfile=$(mktemp)
    echo -e "$info" > "$tmpfile"
    textbox "CPU Information" "$tmpfile"
    rm -f "$tmpfile"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I/O SETTINGS MENU
# ═══════════════════════════════════════════════════════════════════════════════

# I/O settings submenu
run_io_settings_menu() {
    local choice

    while true; do
        local trim_status
        trim_status=$(get_trim_status)

        choice=$(menu_select "I/O & Storage Settings" \
            "Storage: $STORAGE_TYPE | TRIM: $trim_status" \
            "scheduler"  "I/O Scheduler" \
            "trim"       "TRIM Timer ($trim_status)" \
            "info"       "Storage Information" \
            "back"       "Back")

        case "$choice" in
            scheduler)
                configure_scheduler_interactive
                ;;
            trim)
                configure_trim_interactive
                ;;
            info)
                show_storage_info
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# Configure I/O scheduler interactively
configure_scheduler_interactive() {
    # Find a real block device
    local sample_dev=""
    for dev in /sys/block/sd* /sys/block/nvme* /sys/block/vd*; do
        if [[ -d "$dev" ]]; then
            sample_dev=$(basename "$dev")
            break
        fi
    done

    if [[ -z "$sample_dev" ]]; then
        message_box "No Devices" "No block devices found for scheduler configuration."
        return 0
    fi

    local current
    current=$(get_io_scheduler "$sample_dev")
    local available
    available=$(get_available_schedulers "$sample_dev")

    local help_text="I/O Scheduler determines how disk read/write requests are ordered.

Schedulers:
  none       - No scheduling (best for NVMe)
  mq-deadline - Low latency (good for SSD)
  bfq        - Fair queuing (good for HDD/desktop)
  kyber      - Low latency optimized

Current ($sample_dev): $current
Storage type: $STORAGE_TYPE"

    message_box "I/O Scheduler Help" "$help_text"

    # Build menu items
    local menu_items=()
    for sched in $available; do
        local desc
        case "$sched" in
            none)        desc="No scheduling (NVMe)" ;;
            mq-deadline) desc="Low latency (SSD)" ;;
            bfq)         desc="Fair queuing (Desktop/HDD)" ;;
            kyber)       desc="Low latency optimized" ;;
            *)           desc="$sched scheduler" ;;
        esac

        if [[ "$sched" == "$current" ]]; then
            desc="$desc [CURRENT]"
        fi

        menu_items+=("$sched" "$desc")
    done

    local choice
    choice=$(menu_select "Select I/O Scheduler" \
        "Applies to all block devices" \
        "${menu_items[@]}" \
        "back" "Cancel")

    if [[ -n "$choice" ]] && [[ "$choice" != "back" ]]; then
        show_wait "Setting I/O scheduler to $choice..."
        apply_io_scheduler "$choice"
        message_box "Success" "I/O scheduler set to $choice for all devices"
    fi
}

# Configure TRIM timer interactively
configure_trim_interactive() {
    local current_status
    current_status=$(get_trim_status)

    if [[ "$current_status" == "unavailable" ]]; then
        message_box "Not Available" "TRIM timer management is not available (requires systemd)."
        return 0
    fi

    if [[ "$STORAGE_TYPE" != "ssd" ]] && [[ "$STORAGE_TYPE" != "nvme" ]]; then
        message_box "Note" "TRIM is only beneficial for SSD/NVMe storage.\nYour storage type: $STORAGE_TYPE"
    fi

    local help_text="TRIM (fstrim) tells the SSD which blocks are no longer in use, allowing the drive to optimize performance and longevity.

Current status: $current_status

Recommended: Enable for SSD/NVMe storage"

    message_box "TRIM Timer" "$help_text"

    if [[ "$current_status" == "enabled" ]]; then
        if yes_no_prompt "TRIM Timer" "TRIM timer is enabled. Disable it?"; then
            configure_trim 0
            message_box "Success" "TRIM timer disabled"
        fi
    else
        if yes_no_prompt "TRIM Timer" "TRIM timer is disabled. Enable it?"; then
            configure_trim 1
            message_box "Success" "TRIM timer enabled"
        fi
    fi
}

# Show storage information
show_storage_info() {
    local info=""
    info+="Storage Information\n"
    info+="═══════════════════════════════════════\n\n"
    info+="Root Device: ${ROOT_DEVICE:-Unknown}\n"
    info+="Filesystem: ${ROOT_FS_TYPE:-Unknown}\n"
    info+="Storage Type: ${STORAGE_TYPE:-Unknown}\n\n"
    info+="Block Devices:\n"

    for dev in /sys/block/sd* /sys/block/nvme* /sys/block/vd*; do
        if [[ -d "$dev" ]]; then
            local dev_name
            dev_name=$(basename "$dev")
            local scheduler
            scheduler=$(get_io_scheduler "$dev_name")
            local rotational
            rotational=$(cat "$dev/queue/rotational" 2>/dev/null)
            local type="HDD"
            [[ "$rotational" == "0" ]] && type="SSD/NVMe"

            info+="  $dev_name: $type, scheduler=$scheduler\n"
        fi
    done

    info+="\nTRIM Timer: $(get_trim_status)\n"

    local tmpfile
    tmpfile=$(mktemp)
    echo -e "$info" > "$tmpfile"
    textbox "Storage Information" "$tmpfile"
    rm -f "$tmpfile"
}

# ═══════════════════════════════════════════════════════════════════════════════
# NETWORK SETTINGS MENU
# ═══════════════════════════════════════════════════════════════════════════════

# Network settings submenu
run_network_settings_menu() {
    local choice

    while true; do
        local tcp_cc
        tcp_cc=$(get_tcp_congestion)

        choice=$(menu_select "Network Optimization" \
            "TCP Congestion: $tcp_cc" \
            "bbr"       "BBR Congestion Control" \
            "tcp"       "TCP Buffer Tuning" \
            "info"      "Network Information" \
            "back"      "Back")

        case "$choice" in
            bbr)
                configure_bbr_interactive
                ;;
            tcp)
                configure_tcp_tuning_interactive
                ;;
            info)
                show_network_info
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# Configure BBR interactively
configure_bbr_interactive() {
    local current
    current=$(get_tcp_congestion)

    local help_text="BBR (Bottleneck Bandwidth and Round-trip) is Google's TCP congestion control algorithm.

Benefits:
- Better throughput on high-bandwidth connections
- Lower latency
- Works well over WiFi and lossy links

Current: $current
Recommended: Enable for most users"

    message_box "BBR Congestion Control" "$help_text"

    if [[ "$current" == "bbr" ]]; then
        if yes_no_prompt "BBR" "BBR is currently enabled. Switch to cubic (default)?"; then
            disable_bbr
            message_box "Success" "Switched to cubic congestion control"
        fi
    else
        if yes_no_prompt "BBR" "Enable BBR congestion control?"; then
            if enable_bbr; then
                message_box "Success" "BBR enabled"
            else
                message_box "Error" "Failed to enable BBR. Your kernel may not support it."
            fi
        fi
    fi
}

# Configure TCP tuning interactively
configure_tcp_tuning_interactive() {
    local help_text="TCP Buffer Tuning optimizes network buffer sizes for better throughput.

Changes applied:
- Increased max receive/send buffer sizes
- Optimized TCP memory settings
- Enabled TCP window scaling
- Enabled SACK and timestamps

Recommended for: High bandwidth connections, servers"

    message_box "TCP Buffer Tuning" "$help_text"

    if yes_no_prompt "Apply TCP Tuning" "Apply TCP buffer optimizations?"; then
        apply_tcp_tuning
        message_box "Success" "TCP buffer tuning applied"
    fi
}

# Show network information
show_network_info() {
    local info=""
    info+="Network Information\n"
    info+="═══════════════════════════════════════\n\n"
    info+="Interfaces: ${#NETWORK_INTERFACES[@]} total\n"
    info+="  WiFi: ${WIFI_INTERFACES[*]:-none}\n"
    info+="  Ethernet: ${ETH_INTERFACES[*]:-none}\n\n"
    info+="TCP Settings:\n"
    info+="  Congestion Control: $(get_tcp_congestion)\n"
    info+="  Default QDisc: $(get_sysctl_value 'net.core.default_qdisc')\n"
    info+="  Window Scaling: $(get_sysctl_value 'net.ipv4.tcp_window_scaling')\n"
    info+="  SACK: $(get_sysctl_value 'net.ipv4.tcp_sack')\n"

    local tmpfile
    tmpfile=$(mktemp)
    echo -e "$info" > "$tmpfile"
    textbox "Network Information" "$tmpfile"
    rm -f "$tmpfile"
}

# ═══════════════════════════════════════════════════════════════════════════════
# DESKTOP ENVIRONMENT MENU
# ═══════════════════════════════════════════════════════════════════════════════

# Desktop environment settings submenu
run_desktop_settings_menu() {
    local de
    de=$(detect_desktop_environment)

    if [[ "$de" == "unknown" ]]; then
        message_box "Desktop Environment" "No supported desktop environment detected.\n\nSupported: GNOME, KDE Plasma, XFCE, Cinnamon"
        return 0
    fi

    local choice

    choice=$(menu_select "Desktop: $de" \
        "Optimize desktop environment settings" \
        "performance" "Performance Mode (disable effects)" \
        "balanced"    "Balanced Mode (default settings)" \
        "info"        "Desktop Information" \
        "back"        "Back")

    case "$choice" in
        performance)
            if yes_no_prompt "Performance Mode" "Disable animations and effects for better performance?"; then
                apply_desktop_optimizations "performance"
                message_box "Success" "Desktop optimized for performance.\n\nYou may need to log out for all changes to take effect."
            fi
            ;;
        balanced)
            if yes_no_prompt "Balanced Mode" "Restore default desktop settings?"; then
                apply_desktop_optimizations "balanced"
                message_box "Success" "Desktop settings restored to balanced.\n\nYou may need to log out for all changes to take effect."
            fi
            ;;
        info)
            show_desktop_info "$de"
            ;;
    esac
}

# Show desktop environment information
show_desktop_info() {
    local de="$1"

    local info=""
    info+="Desktop Environment Information\n"
    info+="═══════════════════════════════════════\n\n"
    info+="Detected: $de\n\n"

    case "$de" in
        gnome)
            info+="GNOME Options:\n"
            info+="- Animations toggle\n"
            info+="- Tracker indexing control\n"
            ;;
        kde)
            info+="KDE Plasma Options:\n"
            info+="- Desktop effects toggle\n"
            info+="- Baloo indexing control\n"
            ;;
        xfce)
            info+="XFCE Options:\n"
            info+="- Compositor toggle\n"
            ;;
        cinnamon)
            info+="Cinnamon Options:\n"
            info+="- Animations toggle\n"
            info+="- Effects control\n"
            ;;
    esac

    message_box "Desktop Info" "$info"
}

# ═══════════════════════════════════════════════════════════════════════════════
# SAVE/RESET FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Save manual configuration
save_manual_config() {
    if [[ ${#OPT_CHANGES[@]} -eq 0 ]]; then
        message_box "Nothing to Save" "No changes have been made to save."
        return 0
    fi

    if yes_no_prompt "Save Configuration" "Save current settings to persistent configuration?\n\nFile: $SYSCTL_CONF_FILE"; then
        write_sysctl_config
        message_box "Saved" "Configuration saved successfully.\n\nSettings will persist across reboots."
    fi
}

# Reset all optimizations
reset_optimizations() {
    local help_text="This will:
- Remove the suite's sysctl configuration file
- Reset values to system defaults on next boot
- NOT affect other system configurations

Current config: $SYSCTL_CONF_FILE"

    message_box "Reset Optimizations" "$help_text"

    if yes_no_prompt "Confirm Reset" "Remove all suite optimizations?\n\nThis cannot be undone."; then
        remove_sysctl_config
        message_box "Reset Complete" "Optimizations have been removed.\n\nReboot to restore default system values."
    fi
}
