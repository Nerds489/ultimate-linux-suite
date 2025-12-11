#!/usr/bin/env bash
#
# setup_profiles.sh - Setup Profiles Module for Ultimate Linux Suite
#
# Manages system configuration profiles for different use cases
#

# Prevent multiple sourcing
[[ -n "${_MODULE_PROFILES_LOADED:-}" ]] && return 0
readonly _MODULE_PROFILES_LOADED=1

# Profile configuration storage
declare -gA SETUP_PROFILES

# Module initialization
module_profiles_init() {
    log_debug "Setup profiles module initialized"

    # Load default profiles
    _load_default_profiles

    return 0
}

# Load default profile configurations
_load_default_profiles() {
    # Desktop profile
    SETUP_PROFILES[desktop_desc]="General desktop use with balanced settings"
    SETUP_PROFILES[desktop_swappiness]="60"
    SETUP_PROFILES[desktop_governor]="schedutil"
    SETUP_PROFILES[desktop_io_scheduler]="mq-deadline"

    # Gaming profile
    SETUP_PROFILES[gaming_desc]="Optimized for gaming with low latency"
    SETUP_PROFILES[gaming_swappiness]="10"
    SETUP_PROFILES[gaming_governor]="performance"
    SETUP_PROFILES[gaming_io_scheduler]="none"

    # Server profile
    SETUP_PROFILES[server_desc]="Server workload optimization"
    SETUP_PROFILES[server_swappiness]="30"
    SETUP_PROFILES[server_governor]="ondemand"
    SETUP_PROFILES[server_io_scheduler]="mq-deadline"

    # Laptop profile
    SETUP_PROFILES[laptop_desc]="Battery optimization for laptops"
    SETUP_PROFILES[laptop_swappiness]="60"
    SETUP_PROFILES[laptop_governor]="powersave"
    SETUP_PROFILES[laptop_io_scheduler]="bfq"

    # Workstation profile
    SETUP_PROFILES[workstation_desc]="Productivity focused workstation"
    SETUP_PROFILES[workstation_swappiness]="40"
    SETUP_PROFILES[workstation_governor]="schedutil"
    SETUP_PROFILES[workstation_io_scheduler]="bfq"

    # Minimal profile
    SETUP_PROFILES[minimal_desc]="Minimal resource footprint"
    SETUP_PROFILES[minimal_swappiness]="80"
    SETUP_PROFILES[minimal_governor]="powersave"
    SETUP_PROFILES[minimal_io_scheduler]="bfq"

    log_debug "Default profiles loaded"
    return 0
}

# Get profile description
# Arguments:
#   $1 - Profile name
get_profile_description() {
    local profile="$1"
    echo "${SETUP_PROFILES[${profile}_desc]:-No description available}"
}

# Get profile setting
# Arguments:
#   $1 - Profile name
#   $2 - Setting name
get_profile_setting() {
    local profile="$1"
    local setting="$2"
    echo "${SETUP_PROFILES[${profile}_${setting}]:-}"
}

# List available profiles
list_profiles() {
    local profiles=("desktop" "gaming" "server" "laptop" "workstation" "minimal")

    for profile in "${profiles[@]}"; do
        echo "$profile: $(get_profile_description "$profile")"
    done
}

# Apply a complete setup profile
# Arguments:
#   $1 - Profile name
apply_setup_profile() {
    local profile="$1"

    if [[ -z "${SETUP_PROFILES[${profile}_desc]:-}" ]]; then
        log_error "Unknown profile: $profile"
        return 1
    fi

    log_info "Applying setup profile: $profile"
    log_info "Description: $(get_profile_description "$profile")"

    # Apply swappiness
    local swappiness
    swappiness=$(get_profile_setting "$profile" "swappiness")
    if [[ -n "$swappiness" ]]; then
        _apply_swappiness "$swappiness"
    fi

    # Apply CPU governor
    local governor
    governor=$(get_profile_setting "$profile" "governor")
    if [[ -n "$governor" ]]; then
        _apply_cpu_governor "$governor"
    fi

    # Apply I/O scheduler
    local scheduler
    scheduler=$(get_profile_setting "$profile" "io_scheduler")
    if [[ -n "$scheduler" ]]; then
        _apply_io_scheduler "$scheduler"
    fi

    log_info "Profile '$profile' applied successfully"
    return 0
}

# Apply swappiness setting
_apply_swappiness() {
    local value="$1"

    log_debug "Setting swappiness to $value"

    if [[ -w /proc/sys/vm/swappiness ]]; then
        echo "$value" | run_as_root tee /proc/sys/vm/swappiness > /dev/null
        log_debug "Swappiness set to $value"
    else
        log_warn "Cannot modify swappiness"
    fi

    return 0
}

# Apply CPU governor
_apply_cpu_governor() {
    local governor="$1"

    log_debug "Setting CPU governor to $governor"

    if [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
        for cpu_dir in /sys/devices/system/cpu/cpu*/cpufreq; do
            if [[ -w "$cpu_dir/scaling_governor" ]]; then
                echo "$governor" | run_as_root tee "$cpu_dir/scaling_governor" > /dev/null 2>&1
            fi
        done
        log_debug "CPU governor set to $governor"
    else
        log_warn "CPU frequency scaling not available"
    fi

    return 0
}

# Apply I/O scheduler
_apply_io_scheduler() {
    local scheduler="$1"

    log_debug "Setting I/O scheduler to $scheduler"

    for block_dev in /sys/block/*/queue/scheduler; do
        if [[ -w "$block_dev" ]]; then
            echo "$scheduler" | run_as_root tee "$block_dev" > /dev/null 2>&1
        fi
    done

    log_debug "I/O scheduler set to $scheduler"
    return 0
}

# Create custom profile
# Arguments:
#   $1 - Profile name
#   $2 - Description
create_custom_profile() {
    local name="$1"
    local desc="$2"

    if [[ -z "$name" ]]; then
        log_error "Profile name required"
        return 1
    fi

    SETUP_PROFILES[${name}_desc]="${desc:-Custom profile}"
    SETUP_PROFILES[${name}_swappiness]="60"
    SETUP_PROFILES[${name}_governor]="schedutil"
    SETUP_PROFILES[${name}_io_scheduler]="mq-deadline"

    log_info "Custom profile '$name' created"
    return 0
}

# Update profile setting
# Arguments:
#   $1 - Profile name
#   $2 - Setting name
#   $3 - Value
update_profile_setting() {
    local profile="$1"
    local setting="$2"
    local value="$3"

    if [[ -z "${SETUP_PROFILES[${profile}_desc]:-}" ]]; then
        log_error "Profile not found: $profile"
        return 1
    fi

    SETUP_PROFILES[${profile}_${setting}]="$value"
    log_debug "Updated $profile.$setting = $value"
    return 0
}

# Get current system settings
get_current_settings() {
    local current_swappiness
    local current_governor
    local current_scheduler

    current_swappiness=$(cat /proc/sys/vm/swappiness 2>/dev/null || echo "unknown")

    if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
        current_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
    else
        current_governor="unknown"
    fi

    for sched_file in /sys/block/*/queue/scheduler; do
        if [[ -r "$sched_file" ]]; then
            current_scheduler=$(cat "$sched_file" 2>/dev/null | grep -oP '\[\K[^\]]+')
            break
        fi
    done

    echo "Current System Settings:"
    echo "  Swappiness: $current_swappiness"
    echo "  CPU Governor: $current_governor"
    echo "  I/O Scheduler: ${current_scheduler:-unknown}"
}

# Match current settings to a profile
detect_current_profile() {
    local current_swap
    current_swap=$(cat /proc/sys/vm/swappiness 2>/dev/null || echo "60")

    local profiles=("desktop" "gaming" "server" "laptop" "workstation" "minimal")

    for profile in "${profiles[@]}"; do
        local profile_swap
        profile_swap=$(get_profile_setting "$profile" "swappiness")

        if [[ "$current_swap" == "$profile_swap" ]]; then
            echo "$profile"
            return 0
        fi
    done

    echo "custom"
    return 0
}
