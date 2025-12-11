#!/usr/bin/env bash
#
# optimize.sh - System Optimization Module for Ultimate Linux Suite
#
# Provides comprehensive system optimization with auto and manual modes
#

# Prevent multiple sourcing
[[ -n "${_MODULE_OPTIMIZE_LOADED:-}" ]] && return 0
readonly _MODULE_OPTIMIZE_LOADED=1

# Configuration file path for suite-specific sysctl settings
declare -gr SYSCTL_CONF_FILE="/etc/sysctl.d/90-ultimate-linux-suite.conf"
declare -gr SUITE_CONF_DIR="/etc/ultimate-linux-suite"

# Current optimization state
declare -gA OPT_STATE
declare -gA OPT_CHANGES

# RAM profile thresholds (in MB)
declare -gr RAM_MINIMAL=2048       # <= 2GB
declare -gr RAM_LOW=4096           # <= 4GB
declare -gr RAM_MEDIUM=8192        # <= 8GB
declare -gr RAM_HIGH=16384         # <= 16GB
# Above 16GB = Extreme workstation

# Module initialization
module_optimize_init() {
    log_debug "Optimization module initialized"
    OPT_CHANGES=()
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# RAM PROFILE DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

# Determine RAM profile based on system memory
# Returns: profile name (minimal, low, medium, high, extreme)
detect_ram_profile() {
    local ram_mb="${TOTAL_RAM_MB:-0}"

    if [[ $ram_mb -le $RAM_MINIMAL ]]; then
        echo "minimal"
    elif [[ $ram_mb -le $RAM_LOW ]]; then
        echo "low"
    elif [[ $ram_mb -le $RAM_MEDIUM ]]; then
        echo "medium"
    elif [[ $ram_mb -le $RAM_HIGH ]]; then
        echo "high"
    else
        echo "extreme"
    fi
}

# Get RAM profile description
get_ram_profile_description() {
    local profile="$1"

    case "$profile" in
        minimal)  echo "Minimal RAM (<=2GB) - Aggressive memory saving" ;;
        low)      echo "Low RAM (<=4GB) - Memory-conscious settings" ;;
        medium)   echo "Medium RAM (<=8GB) - Balanced performance" ;;
        high)     echo "High RAM (<=16GB) - Performance-oriented" ;;
        extreme)  echo "Extreme (>16GB) - Maximum performance workstation" ;;
        *)        echo "Unknown profile" ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# AUTO-OPTIMIZE MODE
# ═══════════════════════════════════════════════════════════════════════════════

# Main auto-optimize function
run_auto_optimize() {
    log_section "Auto-Optimize"
    log_info "Starting automatic system optimization..."

    # Clear previous changes
    OPT_CHANGES=()

    # Detect system profile
    local ram_profile
    ram_profile=$(detect_ram_profile)
    log_info "Detected RAM profile: $ram_profile (${TOTAL_RAM_MB}MB)"

    # Detect storage type
    local storage="${STORAGE_TYPE:-hdd}"
    log_info "Storage type: $storage"

    # Detect form factor
    local form="${FORM_FACTOR:-desktop}"
    log_info "Form factor: $form"

    # Build optimization plan
    local plan=""
    plan+="═══════════════════════════════════════════════════════════\n"
    plan+="  AUTO-OPTIMIZE PLAN\n"
    plan+="═══════════════════════════════════════════════════════════\n\n"
    plan+="System Analysis:\n"
    plan+="  RAM: ${TOTAL_RAM_MB}MB (Profile: $ram_profile)\n"
    plan+="  Storage: $storage\n"
    plan+="  Form Factor: $form\n"
    plan+="  CPU: ${CPU_VENDOR:-Unknown} (${CPU_CORES:-?} cores)\n\n"

    # Calculate settings based on profile
    local swappiness dirty_ratio dirty_bg_ratio vfs_cache_pressure min_free_kb
    local zram_enabled zram_size cpu_governor io_scheduler

    case "$ram_profile" in
        minimal)
            swappiness=80
            dirty_ratio=10
            dirty_bg_ratio=5
            vfs_cache_pressure=200
            min_free_kb=$((TOTAL_RAM_KB / 64))
            zram_enabled=1
            zram_size=$((TOTAL_RAM_MB / 2))
            cpu_governor="powersave"
            ;;
        low)
            swappiness=60
            dirty_ratio=15
            dirty_bg_ratio=5
            vfs_cache_pressure=150
            min_free_kb=$((TOTAL_RAM_KB / 32))
            zram_enabled=1
            zram_size=$((TOTAL_RAM_MB / 2))
            cpu_governor="schedutil"
            ;;
        medium)
            swappiness=40
            dirty_ratio=20
            dirty_bg_ratio=10
            vfs_cache_pressure=100
            min_free_kb=$((TOTAL_RAM_KB / 32))
            zram_enabled=1
            zram_size=$((TOTAL_RAM_MB / 4))
            cpu_governor="schedutil"
            ;;
        high)
            swappiness=20
            dirty_ratio=30
            dirty_bg_ratio=10
            vfs_cache_pressure=75
            min_free_kb=$((TOTAL_RAM_KB / 64))
            zram_enabled=0
            zram_size=0
            cpu_governor="schedutil"
            ;;
        extreme)
            swappiness=10
            dirty_ratio=40
            dirty_bg_ratio=15
            vfs_cache_pressure=50
            min_free_kb=$((TOTAL_RAM_KB / 128))
            zram_enabled=0
            zram_size=0
            cpu_governor="performance"
            ;;
    esac

    # Adjust for laptop
    if [[ "$form" == "laptop" ]]; then
        cpu_governor="schedutil"
        [[ "$ram_profile" == "extreme" ]] && cpu_governor="schedutil"
    fi

    # Select I/O scheduler based on storage
    case "$storage" in
        nvme)    io_scheduler="none" ;;
        ssd)     io_scheduler="mq-deadline" ;;
        hdd)     io_scheduler="bfq" ;;
        *)       io_scheduler="mq-deadline" ;;
    esac

    # Build plan details
    plan+="Planned Changes:\n\n"
    plan+="  [Memory Management]\n"
    plan+="    vm.swappiness = $swappiness\n"
    plan+="    vm.dirty_ratio = $dirty_ratio\n"
    plan+="    vm.dirty_background_ratio = $dirty_bg_ratio\n"
    plan+="    vm.vfs_cache_pressure = $vfs_cache_pressure\n"
    plan+="    vm.min_free_kbytes = $min_free_kb\n"
    if [[ $zram_enabled -eq 1 ]]; then
        plan+="    ZRAM = Enabled (${zram_size}MB)\n"
    else
        plan+="    ZRAM = Disabled\n"
    fi
    plan+="\n  [CPU]\n"
    plan+="    Governor = $cpu_governor\n"
    plan+="\n  [I/O]\n"
    plan+="    Scheduler = $io_scheduler\n"
    plan+="\n"
    plan+="═══════════════════════════════════════════════════════════\n"

    # Store planned changes
    OPT_CHANGES[swappiness]="$swappiness"
    OPT_CHANGES[dirty_ratio]="$dirty_ratio"
    OPT_CHANGES[dirty_bg_ratio]="$dirty_bg_ratio"
    OPT_CHANGES[vfs_cache_pressure]="$vfs_cache_pressure"
    OPT_CHANGES[min_free_kb]="$min_free_kb"
    OPT_CHANGES[zram_enabled]="$zram_enabled"
    OPT_CHANGES[zram_size]="$zram_size"
    OPT_CHANGES[cpu_governor]="$cpu_governor"
    OPT_CHANGES[io_scheduler]="$io_scheduler"

    # Show plan and confirm
    local tmpfile
    tmpfile=$(mktemp)
    echo -e "$plan" > "$tmpfile"

    if [[ "$MENU_BACKEND" == "text" ]]; then
        echo -e "$plan"
        echo ""
        if ! confirm "Apply these optimizations?"; then
            log_info "Auto-optimize cancelled by user"
            rm -f "$tmpfile"
            return 1
        fi
    else
        textbox "Auto-Optimize Plan" "$tmpfile"
        rm -f "$tmpfile"

        if ! yes_no_prompt "Confirm" "Apply these optimizations?"; then
            log_info "Auto-optimize cancelled by user"
            return 1
        fi
    fi

    # Apply optimizations
    log_info "Applying optimizations..."

    apply_memory_optimizations "$swappiness" "$dirty_ratio" "$dirty_bg_ratio" \
                               "$vfs_cache_pressure" "$min_free_kb"

    if [[ $zram_enabled -eq 1 ]]; then
        configure_zram "$zram_size"
    fi

    apply_cpu_governor "$cpu_governor"
    apply_io_scheduler "$io_scheduler"

    # Write persistent configuration
    write_sysctl_config

    log_info "Auto-optimization complete!"
    message_box "Complete" "System optimizations have been applied.\n\nA reboot is recommended for all changes to take full effect."

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# MEMORY OPTIMIZATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Apply memory-related optimizations
apply_memory_optimizations() {
    local swappiness="$1"
    local dirty_ratio="$2"
    local dirty_bg_ratio="$3"
    local vfs_cache_pressure="$4"
    local min_free_kb="$5"

    log_info "Applying memory optimizations..."

    # Runtime changes
    set_sysctl_value "vm.swappiness" "$swappiness"
    set_sysctl_value "vm.dirty_ratio" "$dirty_ratio"
    set_sysctl_value "vm.dirty_background_ratio" "$dirty_bg_ratio"
    set_sysctl_value "vm.vfs_cache_pressure" "$vfs_cache_pressure"
    set_sysctl_value "vm.min_free_kbytes" "$min_free_kb"

    log_debug "Memory optimizations applied"
}

# Set a sysctl value at runtime
set_sysctl_value() {
    local key="$1"
    local value="$2"
    local sysfs_path="/proc/sys/${key//./\/}"

    if [[ -w "$sysfs_path" ]]; then
        echo "$value" | run_as_root tee "$sysfs_path" > /dev/null 2>&1
        log_debug "Set $key = $value"
    elif is_root; then
        sysctl -w "${key}=${value}" > /dev/null 2>&1
        log_debug "Set $key = $value (via sysctl)"
    else
        run_as_root sysctl -w "${key}=${value}" > /dev/null 2>&1
        log_debug "Set $key = $value (via sudo sysctl)"
    fi
}

# Get current sysctl value
get_sysctl_value() {
    local key="$1"
    local sysfs_path="/proc/sys/${key//./\/}"

    if [[ -r "$sysfs_path" ]]; then
        cat "$sysfs_path" 2>/dev/null
    else
        sysctl -n "$key" 2>/dev/null
    fi
}

# Configure ZRAM
configure_zram() {
    local size_mb="$1"

    log_info "Configuring ZRAM (${size_mb}MB)..."

    # Check if zram module is available
    if ! have_cmd modprobe; then
        log_warn "modprobe not available, skipping ZRAM"
        return 1
    fi

    # Load zram module if not loaded
    if [[ ! -d /sys/block/zram0 ]]; then
        run_as_root modprobe zram num_devices=1 2>/dev/null || {
            log_warn "Failed to load zram module"
            return 1
        }
    fi

    # Check if zram0 exists now
    if [[ ! -d /sys/block/zram0 ]]; then
        log_warn "ZRAM device not available"
        return 1
    fi

    # Reset and configure
    if [[ -f /sys/block/zram0/reset ]]; then
        # First, disable any existing swap on zram0
        swapoff /dev/zram0 2>/dev/null

        # Reset the device
        echo 1 | run_as_root tee /sys/block/zram0/reset > /dev/null 2>&1
    fi

    # Set compression algorithm (lz4 is fast, zstd is better ratio)
    if [[ -f /sys/block/zram0/comp_algorithm ]]; then
        local algo="lz4"
        if grep -q zstd /sys/block/zram0/comp_algorithm 2>/dev/null; then
            algo="zstd"
        fi
        echo "$algo" | run_as_root tee /sys/block/zram0/comp_algorithm > /dev/null 2>&1
    fi

    # Set disk size
    local size_bytes=$((size_mb * 1024 * 1024))
    echo "$size_bytes" | run_as_root tee /sys/block/zram0/disksize > /dev/null 2>&1

    # Setup swap
    run_as_root mkswap /dev/zram0 > /dev/null 2>&1
    run_as_root swapon -p 100 /dev/zram0 2>/dev/null

    log_info "ZRAM configured: ${size_mb}MB"
    return 0
}

# Disable ZRAM
disable_zram() {
    log_info "Disabling ZRAM..."

    if [[ -b /dev/zram0 ]]; then
        run_as_root swapoff /dev/zram0 2>/dev/null
        if [[ -f /sys/block/zram0/reset ]]; then
            echo 1 | run_as_root tee /sys/block/zram0/reset > /dev/null 2>&1
        fi
    fi

    log_debug "ZRAM disabled"
}

# Get ZRAM status
get_zram_status() {
    if [[ -d /sys/block/zram0 ]] && swapon --show 2>/dev/null | grep -q zram; then
        local size_bytes
        size_bytes=$(cat /sys/block/zram0/disksize 2>/dev/null || echo 0)
        local size_mb=$((size_bytes / 1024 / 1024))
        echo "enabled:${size_mb}MB"
    else
        echo "disabled"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# CPU OPTIMIZATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Apply CPU governor
apply_cpu_governor() {
    local governor="$1"

    log_info "Setting CPU governor to: $governor"

    # Check if cpufreq is available
    if [[ ! -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
        log_warn "CPU frequency scaling not available"
        return 1
    fi

    # Check if governor is available
    local available_governors
    available_governors=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null)

    if [[ ! " $available_governors " =~ " $governor " ]]; then
        log_warn "Governor '$governor' not available. Available: $available_governors"
        # Fall back to schedutil or ondemand
        if [[ " $available_governors " =~ " schedutil " ]]; then
            governor="schedutil"
        elif [[ " $available_governors " =~ " ondemand " ]]; then
            governor="ondemand"
        else
            log_error "No suitable governor found"
            return 1
        fi
        log_info "Using fallback governor: $governor"
    fi

    # Apply to all CPUs
    for cpu_dir in /sys/devices/system/cpu/cpu*/cpufreq; do
        if [[ -w "$cpu_dir/scaling_governor" ]]; then
            echo "$governor" | run_as_root tee "$cpu_dir/scaling_governor" > /dev/null 2>&1
        fi
    done

    log_debug "CPU governor set to $governor"
    return 0
}

# Get current CPU governor
get_cpu_governor() {
    if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null
    else
        echo "unknown"
    fi
}

# Get available CPU governors
get_available_governors() {
    if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors ]]; then
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null
    else
        echo "none"
    fi
}

# Toggle CPU turbo boost
toggle_turbo_boost() {
    local enable="$1"  # 1 = enable, 0 = disable

    log_info "Setting turbo boost: $([ "$enable" -eq 1 ] && echo 'enabled' || echo 'disabled')"

    # Intel turbo
    if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
        local value=$((1 - enable))  # Intel uses inverted logic
        echo "$value" | run_as_root tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null 2>&1
        return 0
    fi

    # AMD boost
    if [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
        echo "$enable" | run_as_root tee /sys/devices/system/cpu/cpufreq/boost > /dev/null 2>&1
        return 0
    fi

    log_warn "Turbo boost control not available on this system"
    return 1
}

# Get turbo boost status
get_turbo_status() {
    # Intel
    if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
        local no_turbo
        no_turbo=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null)
        [[ "$no_turbo" == "0" ]] && echo "enabled" || echo "disabled"
        return 0
    fi

    # AMD
    if [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
        local boost
        boost=$(cat /sys/devices/system/cpu/cpufreq/boost 2>/dev/null)
        [[ "$boost" == "1" ]] && echo "enabled" || echo "disabled"
        return 0
    fi

    echo "unavailable"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I/O OPTIMIZATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Apply I/O scheduler
apply_io_scheduler() {
    local scheduler="$1"

    log_info "Setting I/O scheduler to: $scheduler"

    for block_dev in /sys/block/*/queue/scheduler; do
        if [[ -w "$block_dev" ]]; then
            # Get device name
            local dev_name
            dev_name=$(echo "$block_dev" | cut -d/ -f4)

            # Skip certain devices
            [[ "$dev_name" == loop* ]] && continue
            [[ "$dev_name" == ram* ]] && continue
            [[ "$dev_name" == zram* ]] && continue

            # Check if scheduler is available
            local available
            available=$(cat "$block_dev" 2>/dev/null)

            if [[ "$available" == *"$scheduler"* ]] || [[ "$available" == *"[$scheduler]"* ]]; then
                echo "$scheduler" | run_as_root tee "$block_dev" > /dev/null 2>&1
                log_debug "Set scheduler for $dev_name: $scheduler"
            else
                log_debug "Scheduler $scheduler not available for $dev_name"
            fi
        fi
    done

    return 0
}

# Get current I/O scheduler for a device
get_io_scheduler() {
    local device="${1:-sda}"
    local scheduler_file="/sys/block/$device/queue/scheduler"

    if [[ -r "$scheduler_file" ]]; then
        # Extract the currently selected scheduler (in brackets)
        cat "$scheduler_file" 2>/dev/null | grep -oP '\[\K[^\]]+'
    else
        echo "unknown"
    fi
}

# Get available I/O schedulers
get_available_schedulers() {
    local device="${1:-sda}"
    local scheduler_file="/sys/block/$device/queue/scheduler"

    if [[ -r "$scheduler_file" ]]; then
        cat "$scheduler_file" 2>/dev/null | tr -d '[]'
    else
        echo "none"
    fi
}

# Enable/disable TRIM timer
configure_trim() {
    local enable="$1"  # 1 = enable, 0 = disable

    log_info "Configuring TRIM: $([ "$enable" -eq 1 ] && echo 'enabled' || echo 'disabled')"

    if ! have_cmd systemctl; then
        log_warn "systemd not available, cannot configure TRIM timer"
        return 1
    fi

    if [[ "$enable" -eq 1 ]]; then
        run_as_root systemctl enable fstrim.timer 2>/dev/null
        run_as_root systemctl start fstrim.timer 2>/dev/null
    else
        run_as_root systemctl stop fstrim.timer 2>/dev/null
        run_as_root systemctl disable fstrim.timer 2>/dev/null
    fi

    return 0
}

# Get TRIM timer status
get_trim_status() {
    if have_cmd systemctl; then
        if systemctl is-enabled fstrim.timer &>/dev/null; then
            echo "enabled"
        else
            echo "disabled"
        fi
    else
        echo "unavailable"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# NETWORK OPTIMIZATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Enable BBR congestion control
enable_bbr() {
    log_info "Enabling BBR congestion control..."

    # Check if BBR is available
    if ! grep -q bbr /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
        # Try to load the module
        run_as_root modprobe tcp_bbr 2>/dev/null

        if ! grep -q bbr /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
            log_warn "BBR not available on this kernel"
            return 1
        fi
    fi

    set_sysctl_value "net.core.default_qdisc" "fq"
    set_sysctl_value "net.ipv4.tcp_congestion_control" "bbr"

    OPT_CHANGES[tcp_congestion]="bbr"
    OPT_CHANGES[default_qdisc]="fq"

    log_info "BBR enabled"
    return 0
}

# Disable BBR (revert to cubic)
disable_bbr() {
    log_info "Disabling BBR (reverting to cubic)..."

    set_sysctl_value "net.ipv4.tcp_congestion_control" "cubic"
    set_sysctl_value "net.core.default_qdisc" "pfifo_fast"

    OPT_CHANGES[tcp_congestion]="cubic"
    OPT_CHANGES[default_qdisc]="pfifo_fast"

    log_info "Reverted to cubic"
    return 0
}

# Get current congestion control
get_tcp_congestion() {
    get_sysctl_value "net.ipv4.tcp_congestion_control"
}

# Apply TCP buffer tuning
apply_tcp_tuning() {
    log_info "Applying TCP buffer optimizations..."

    # Increase max buffer sizes
    set_sysctl_value "net.core.rmem_max" "16777216"
    set_sysctl_value "net.core.wmem_max" "16777216"
    set_sysctl_value "net.ipv4.tcp_rmem" "4096 87380 16777216"
    set_sysctl_value "net.ipv4.tcp_wmem" "4096 65536 16777216"

    # Enable TCP window scaling
    set_sysctl_value "net.ipv4.tcp_window_scaling" "1"

    # Enable timestamps for better RTT calculation
    set_sysctl_value "net.ipv4.tcp_timestamps" "1"

    # Enable SACK
    set_sysctl_value "net.ipv4.tcp_sack" "1"

    OPT_CHANGES[tcp_tuning]="applied"

    log_info "TCP buffer optimizations applied"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# DESKTOP ENVIRONMENT OPTIMIZATIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Detect desktop environment
detect_desktop_environment() {
    local de="${XDG_CURRENT_DESKTOP:-}"
    de="${de,,}"  # lowercase

    if [[ -n "$de" ]]; then
        case "$de" in
            *gnome*)    echo "gnome" ;;
            *kde*)      echo "kde" ;;
            *plasma*)   echo "kde" ;;
            *xfce*)     echo "xfce" ;;
            *cinnamon*) echo "cinnamon" ;;
            *mate*)     echo "mate" ;;
            *lxqt*)     echo "lxqt" ;;
            *lxde*)     echo "lxde" ;;
            *budgie*)   echo "budgie" ;;
            *)          echo "unknown" ;;
        esac
        return 0
    fi

    # Fallback detection
    if have_cmd gnome-shell; then
        echo "gnome"
    elif have_cmd plasmashell; then
        echo "kde"
    elif have_cmd xfce4-session; then
        echo "xfce"
    elif have_cmd cinnamon; then
        echo "cinnamon"
    else
        echo "unknown"
    fi
}

# Optimize GNOME
optimize_gnome() {
    local mode="$1"  # balanced, performance, minimal

    log_info "Optimizing GNOME desktop ($mode mode)..."

    if ! have_cmd gsettings; then
        log_warn "gsettings not available"
        return 1
    fi

    case "$mode" in
        performance|minimal)
            # Disable animations
            gsettings set org.gnome.desktop.interface enable-animations false 2>/dev/null

            # Reduce tracker indexing
            if have_cmd tracker3; then
                gsettings set org.freedesktop.Tracker3.Miner.Files crawling-interval -2 2>/dev/null
            fi
            ;;
        balanced)
            # Enable animations
            gsettings set org.gnome.desktop.interface enable-animations true 2>/dev/null
            ;;
    esac

    log_info "GNOME optimizations applied"
    return 0
}

# Optimize KDE Plasma
optimize_kde() {
    local mode="$1"  # balanced, performance, minimal

    log_info "Optimizing KDE Plasma ($mode mode)..."

    # KDE uses kwriteconfig5/kwriteconfig6
    local kwrite=""
    if have_cmd kwriteconfig6; then
        kwrite="kwriteconfig6"
    elif have_cmd kwriteconfig5; then
        kwrite="kwriteconfig5"
    else
        log_warn "kwriteconfig not available"
        return 1
    fi

    case "$mode" in
        performance|minimal)
            # Disable desktop effects
            $kwrite --file kwinrc --group Compositing --key Enabled false 2>/dev/null

            # Disable Baloo indexing
            if have_cmd balooctl6 || have_cmd balooctl; then
                local balooctl_cmd
                balooctl_cmd=$(have_cmd balooctl6 && echo "balooctl6" || echo "balooctl")
                $balooctl_cmd disable 2>/dev/null
            fi
            ;;
        balanced)
            # Enable desktop effects
            $kwrite --file kwinrc --group Compositing --key Enabled true 2>/dev/null
            ;;
    esac

    log_info "KDE optimizations applied"
    return 0
}

# Optimize XFCE
optimize_xfce() {
    local mode="$1"

    log_info "Optimizing XFCE ($mode mode)..."

    if ! have_cmd xfconf-query; then
        log_warn "xfconf-query not available"
        return 1
    fi

    case "$mode" in
        performance|minimal)
            # Disable compositor
            xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null
            ;;
        balanced)
            # Enable compositor
            xfconf-query -c xfwm4 -p /general/use_compositing -s true 2>/dev/null
            ;;
    esac

    log_info "XFCE optimizations applied"
    return 0
}

# Optimize Cinnamon
optimize_cinnamon() {
    local mode="$1"

    log_info "Optimizing Cinnamon ($mode mode)..."

    if ! have_cmd gsettings; then
        log_warn "gsettings not available"
        return 1
    fi

    case "$mode" in
        performance|minimal)
            # Disable effects
            gsettings set org.cinnamon.desktop.interface gtk-enable-animations false 2>/dev/null
            gsettings set org.cinnamon enable-vfade false 2>/dev/null
            ;;
        balanced)
            gsettings set org.cinnamon.desktop.interface gtk-enable-animations true 2>/dev/null
            gsettings set org.cinnamon enable-vfade true 2>/dev/null
            ;;
    esac

    log_info "Cinnamon optimizations applied"
    return 0
}

# Apply desktop optimizations based on detected DE
apply_desktop_optimizations() {
    local mode="${1:-balanced}"
    local de
    de=$(detect_desktop_environment)

    log_info "Detected desktop environment: $de"

    case "$de" in
        gnome)    optimize_gnome "$mode" ;;
        kde)      optimize_kde "$mode" ;;
        xfce)     optimize_xfce "$mode" ;;
        cinnamon) optimize_cinnamon "$mode" ;;
        *)        log_info "No specific optimizations for $de" ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# PERSISTENT CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

# Write sysctl configuration to persistent file
write_sysctl_config() {
    log_info "Writing persistent sysctl configuration..."

    # Ensure directory exists
    run_as_root mkdir -p "$(dirname "$SYSCTL_CONF_FILE")" 2>/dev/null

    # Build configuration content
    local config=""
    config+="# Ultimate Linux Suite - System Optimizations\n"
    config+="# Generated: $(date)\n"
    config+="# WARNING: This file is managed by Ultimate Linux Suite\n"
    config+="#          Manual changes may be overwritten\n"
    config+="\n"

    # Memory settings
    config+="# Memory Management\n"
    [[ -n "${OPT_CHANGES[swappiness]:-}" ]] && \
        config+="vm.swappiness = ${OPT_CHANGES[swappiness]}\n"
    [[ -n "${OPT_CHANGES[dirty_ratio]:-}" ]] && \
        config+="vm.dirty_ratio = ${OPT_CHANGES[dirty_ratio]}\n"
    [[ -n "${OPT_CHANGES[dirty_bg_ratio]:-}" ]] && \
        config+="vm.dirty_background_ratio = ${OPT_CHANGES[dirty_bg_ratio]}\n"
    [[ -n "${OPT_CHANGES[vfs_cache_pressure]:-}" ]] && \
        config+="vm.vfs_cache_pressure = ${OPT_CHANGES[vfs_cache_pressure]}\n"
    [[ -n "${OPT_CHANGES[min_free_kb]:-}" ]] && \
        config+="vm.min_free_kbytes = ${OPT_CHANGES[min_free_kb]}\n"

    # Network settings
    if [[ -n "${OPT_CHANGES[tcp_congestion]:-}" ]]; then
        config+="\n# Network\n"
        config+="net.ipv4.tcp_congestion_control = ${OPT_CHANGES[tcp_congestion]}\n"
        [[ -n "${OPT_CHANGES[default_qdisc]:-}" ]] && \
            config+="net.core.default_qdisc = ${OPT_CHANGES[default_qdisc]}\n"
    fi

    if [[ -n "${OPT_CHANGES[tcp_tuning]:-}" ]]; then
        config+="\n# TCP Tuning\n"
        config+="net.core.rmem_max = 16777216\n"
        config+="net.core.wmem_max = 16777216\n"
        config+="net.ipv4.tcp_rmem = 4096 87380 16777216\n"
        config+="net.ipv4.tcp_wmem = 4096 65536 16777216\n"
        config+="net.ipv4.tcp_window_scaling = 1\n"
        config+="net.ipv4.tcp_timestamps = 1\n"
        config+="net.ipv4.tcp_sack = 1\n"
    fi

    # Write file
    echo -e "$config" | run_as_root tee "$SYSCTL_CONF_FILE" > /dev/null 2>&1

    # Reload sysctl
    run_as_root sysctl --system > /dev/null 2>&1

    log_info "Persistent configuration saved to $SYSCTL_CONF_FILE"
    return 0
}

# Remove suite sysctl configuration
remove_sysctl_config() {
    log_info "Removing suite sysctl configuration..."

    if [[ -f "$SYSCTL_CONF_FILE" ]]; then
        run_as_root rm -f "$SYSCTL_CONF_FILE"
        run_as_root sysctl --system > /dev/null 2>&1
        log_info "Configuration removed"
    else
        log_debug "No configuration file to remove"
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# VIEW CURRENT STATE
# ═══════════════════════════════════════════════════════════════════════════════

# Get comprehensive current optimization state
get_current_optimization_state() {
    local state=""

    state+="═══════════════════════════════════════════════════════════\n"
    state+="  CURRENT SYSTEM OPTIMIZATION STATE\n"
    state+="═══════════════════════════════════════════════════════════\n\n"

    # Memory
    state+="[Memory Management]\n"
    state+="  vm.swappiness = $(get_sysctl_value 'vm.swappiness')\n"
    state+="  vm.dirty_ratio = $(get_sysctl_value 'vm.dirty_ratio')\n"
    state+="  vm.dirty_background_ratio = $(get_sysctl_value 'vm.dirty_background_ratio')\n"
    state+="  vm.vfs_cache_pressure = $(get_sysctl_value 'vm.vfs_cache_pressure')\n"
    state+="  vm.min_free_kbytes = $(get_sysctl_value 'vm.min_free_kbytes')\n"
    state+="  ZRAM Status = $(get_zram_status)\n\n"

    # CPU
    state+="[CPU]\n"
    state+="  Governor = $(get_cpu_governor)\n"
    state+="  Available Governors = $(get_available_governors)\n"
    state+="  Turbo Boost = $(get_turbo_status)\n\n"

    # I/O
    state+="[I/O & Storage]\n"
    local dev
    for dev in /sys/block/sd* /sys/block/nvme* /sys/block/vd*; do
        [[ -d "$dev" ]] || continue
        local dev_name
        dev_name=$(basename "$dev")
        state+="  $dev_name Scheduler = $(get_io_scheduler "$dev_name")\n"
    done
    state+="  TRIM Timer = $(get_trim_status)\n\n"

    # Network
    state+="[Network]\n"
    state+="  TCP Congestion = $(get_tcp_congestion)\n"
    state+="  Default QDisc = $(get_sysctl_value 'net.core.default_qdisc')\n\n"

    # Desktop
    local de
    de=$(detect_desktop_environment)
    state+="[Desktop Environment]\n"
    state+="  Detected = $de\n\n"

    # Suite config
    state+="[Suite Configuration]\n"
    if [[ -f "$SYSCTL_CONF_FILE" ]]; then
        state+="  Config File = $SYSCTL_CONF_FILE (exists)\n"
    else
        state+="  Config File = Not created\n"
    fi

    state+="═══════════════════════════════════════════════════════════\n"

    echo -e "$state"
}

# ═══════════════════════════════════════════════════════════════════════════════
# MANUAL SETTING FUNCTIONS (for expert mode)
# ═══════════════════════════════════════════════════════════════════════════════

# Set swappiness with validation
manual_set_swappiness() {
    local value="$1"

    if [[ ! "$value" =~ ^[0-9]+$ ]] || [[ "$value" -lt 0 ]] || [[ "$value" -gt 100 ]]; then
        log_error "Invalid swappiness value: $value (must be 0-100)"
        return 1
    fi

    set_sysctl_value "vm.swappiness" "$value"
    OPT_CHANGES[swappiness]="$value"
    log_info "Swappiness set to $value"
    return 0
}

# Set dirty ratio with validation
manual_set_dirty_ratio() {
    local value="$1"

    if [[ ! "$value" =~ ^[0-9]+$ ]] || [[ "$value" -lt 1 ]] || [[ "$value" -gt 100 ]]; then
        log_error "Invalid dirty_ratio value: $value (must be 1-100)"
        return 1
    fi

    set_sysctl_value "vm.dirty_ratio" "$value"
    OPT_CHANGES[dirty_ratio]="$value"
    log_info "dirty_ratio set to $value"
    return 0
}

# Set dirty background ratio with validation
manual_set_dirty_bg_ratio() {
    local value="$1"

    if [[ ! "$value" =~ ^[0-9]+$ ]] || [[ "$value" -lt 1 ]] || [[ "$value" -gt 100 ]]; then
        log_error "Invalid dirty_background_ratio value: $value (must be 1-100)"
        return 1
    fi

    set_sysctl_value "vm.dirty_background_ratio" "$value"
    OPT_CHANGES[dirty_bg_ratio]="$value"
    log_info "dirty_background_ratio set to $value"
    return 0
}

# Set VFS cache pressure with validation
manual_set_vfs_cache_pressure() {
    local value="$1"

    if [[ ! "$value" =~ ^[0-9]+$ ]] || [[ "$value" -lt 0 ]] || [[ "$value" -gt 500 ]]; then
        log_error "Invalid vfs_cache_pressure value: $value (must be 0-500)"
        return 1
    fi

    set_sysctl_value "vm.vfs_cache_pressure" "$value"
    OPT_CHANGES[vfs_cache_pressure]="$value"
    log_info "vfs_cache_pressure set to $value"
    return 0
}

# Set min_free_kbytes with validation
manual_set_min_free_kb() {
    local value="$1"
    local max_value=$((TOTAL_RAM_KB / 4))

    if [[ ! "$value" =~ ^[0-9]+$ ]] || [[ "$value" -lt 1024 ]] || [[ "$value" -gt "$max_value" ]]; then
        log_error "Invalid min_free_kbytes value: $value (must be 1024-$max_value)"
        return 1
    fi

    set_sysctl_value "vm.min_free_kbytes" "$value"
    OPT_CHANGES[min_free_kb]="$value"
    log_info "min_free_kbytes set to $value"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# LEGACY COMPATIBILITY (keeping old function names working)
# ═══════════════════════════════════════════════════════════════════════════════

# Apply an optimization profile (legacy wrapper)
module_apply_profile() {
    local profile="$1"

    log_info "Applying optimization profile: $profile"

    case "$profile" in
        desktop)
            OPT_CHANGES=()
            apply_memory_optimizations 60 20 10 100 $((TOTAL_RAM_KB / 32))
            apply_cpu_governor "schedutil"
            apply_io_scheduler "mq-deadline"
            write_sysctl_config
            ;;
        gaming)
            OPT_CHANGES=()
            apply_memory_optimizations 10 10 5 50 $((TOTAL_RAM_KB / 64))
            apply_cpu_governor "performance"
            apply_io_scheduler "none"
            write_sysctl_config
            ;;
        server)
            OPT_CHANGES=()
            apply_memory_optimizations 30 40 10 50 $((TOTAL_RAM_KB / 32))
            apply_cpu_governor "ondemand"
            apply_io_scheduler "mq-deadline"
            enable_bbr
            apply_tcp_tuning
            write_sysctl_config
            ;;
        laptop)
            OPT_CHANGES=()
            apply_memory_optimizations 60 30 5 100 $((TOTAL_RAM_KB / 32))
            apply_cpu_governor "powersave"
            apply_io_scheduler "bfq"
            write_sysctl_config
            ;;
        workstation)
            OPT_CHANGES=()
            apply_memory_optimizations 40 30 10 75 $((TOTAL_RAM_KB / 32))
            apply_cpu_governor "schedutil"
            apply_io_scheduler "mq-deadline"
            write_sysctl_config
            ;;
        minimal)
            OPT_CHANGES=()
            apply_memory_optimizations 80 40 10 150 $((TOTAL_RAM_KB / 64))
            apply_cpu_governor "powersave"
            apply_io_scheduler "bfq"
            configure_zram $((TOTAL_RAM_MB / 2))
            write_sysctl_config
            ;;
        *)
            log_warn "Unknown profile: $profile"
            return 1
            ;;
    esac

    return 0
}

# Get swappiness (legacy)
get_swappiness() {
    get_sysctl_value "vm.swappiness"
}

# Get dirty ratio (legacy)
get_dirty_ratio() {
    get_sysctl_value "vm.dirty_ratio"
}

# Check if optimization feature is available
is_optimization_available() {
    local feature="$1"

    case "$feature" in
        swappiness)
            [[ -f /proc/sys/vm/swappiness ]]
            ;;
        io_scheduler)
            [[ -d /sys/block ]]
            ;;
        hugepages)
            [[ -f /proc/sys/vm/nr_hugepages ]]
            ;;
        cpu_governor)
            [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]
            ;;
        zram)
            have_cmd modprobe && [[ -d /sys/block/zram0 || -f /lib/modules/$(uname -r)/kernel/drivers/block/zram/zram.ko* ]]
            ;;
        bbr)
            [[ -f /proc/sys/net/ipv4/tcp_available_congestion_control ]]
            ;;
        turbo)
            [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]] || \
            [[ -f /sys/devices/system/cpu/cpufreq/boost ]]
            ;;
        *)
            return 1
            ;;
    esac
}
