#!/usr/bin/env bash
#
# recovery.sh - Recovery Module for Ultimate Linux Suite
#
# Provides system recovery, repair tools, and maintenance functions
# including package manager repair, initramfs, DKMS, bootloader, and networking
#

# Prevent multiple sourcing
[[ -n "${_MODULE_RECOVERY_LOADED:-}" ]] && return 0
readonly _MODULE_RECOVERY_LOADED=1

# ============================================================================
# GLOBAL VARIABLES
# ============================================================================

# Backup directory
declare -g BACKUP_DIR="${BACKUP_DIR:-$HOME/.suite-backups}"

# Recovery log
declare -g RECOVERY_LOG=""

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

module_recovery_init() {
    log_debug "Recovery module initialized"

    # Ensure backup directory exists
    mkdir -p "$BACKUP_DIR" 2>/dev/null

    # Initialize recovery log
    RECOVERY_LOG=""

    return 0
}

# ============================================================================
# BACKUP FUNCTIONS
# ============================================================================

# Create system backup
module_create_backup() {
    local backup_type="$1"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="${backup_type}_backup_${timestamp}"

    log_info "Creating $backup_type backup: $backup_name"

    case "$backup_type" in
        home)
            _backup_home "$backup_name"
            ;;
        system)
            _backup_system "$backup_name"
            ;;
        config)
            _backup_configs "$backup_name"
            ;;
        packages)
            _backup_package_list "$backup_name"
            ;;
        grub)
            _backup_grub_config "$backup_name"
            ;;
        *)
            log_error "Unknown backup type: $backup_type"
            return 1
            ;;
    esac

    return 0
}

# Backup home directory
_backup_home() {
    local backup_name="$1"
    local backup_path="$BACKUP_DIR/${backup_name}.tar.gz"

    log_debug "Backing up home directory to $backup_path"

    tar --exclude='.cache' \
        --exclude='.local/share/Trash' \
        --exclude='snap' \
        --exclude='.steam' \
        --exclude='.var' \
        --exclude='.cargo' \
        --exclude='.rustup' \
        --exclude='node_modules' \
        -czf "$backup_path" \
        -C "$HOME" . 2>/dev/null

    if [[ -f "$backup_path" ]]; then
        log_info "Home backup created: $backup_path"
        return 0
    else
        log_error "Failed to create home backup"
        return 1
    fi
}

# Backup system configurations
_backup_system() {
    local backup_name="$1"
    local backup_path="$BACKUP_DIR/${backup_name}.tar.gz"

    log_debug "Creating system backup"

    run_as_root tar -czf "$backup_path" \
        /etc/fstab \
        /etc/default/grub \
        /etc/modprobe.d \
        /etc/sysctl.conf \
        /etc/sysctl.d \
        /etc/NetworkManager \
        /etc/systemd/system \
        2>/dev/null

    if [[ -f "$backup_path" ]]; then
        log_info "System backup created: $backup_path"
        return 0
    else
        log_error "Failed to create system backup"
        return 1
    fi
}

# Backup user configurations
_backup_configs() {
    local backup_name="$1"
    local backup_path="$BACKUP_DIR/${backup_name}.tar.gz"
    local config_dirs=(
        ".bashrc"
        ".zshrc"
        ".profile"
        ".config"
        ".local/share/applications"
    )

    log_debug "Backing up configurations to $backup_path"

    local existing_dirs=()
    for dir in "${config_dirs[@]}"; do
        [[ -e "$HOME/$dir" ]] && existing_dirs+=("$dir")
    done

    if [[ ${#existing_dirs[@]} -gt 0 ]]; then
        tar -czf "$backup_path" -C "$HOME" "${existing_dirs[@]}" 2>/dev/null
        log_info "Config backup created: $backup_path"
    else
        log_warn "No configuration files found to backup"
    fi

    return 0
}

# Backup installed package list
_backup_package_list() {
    local backup_name="$1"
    local backup_path="$BACKUP_DIR/${backup_name}.txt"

    log_debug "Backing up package list to $backup_path"

    case "$PKG_MANAGER" in
        apt)
            dpkg --get-selections > "$backup_path" 2>/dev/null
            ;;
        dnf|yum)
            rpm -qa --qf '%{NAME}\n' | sort > "$backup_path" 2>/dev/null
            ;;
        pacman)
            pacman -Qe > "$backup_path" 2>/dev/null
            ;;
        zypper)
            rpm -qa --qf '%{NAME}\n' | sort > "$backup_path" 2>/dev/null
            ;;
        *)
            log_warn "Package list backup not supported for $PKG_MANAGER"
            return 1
            ;;
    esac

    if [[ -s "$backup_path" ]]; then
        log_info "Package list backup created: $backup_path"
        return 0
    else
        log_error "Failed to create package list backup"
        return 1
    fi
}

# Backup GRUB configuration
_backup_grub_config() {
    local backup_name="$1"
    local backup_path="$BACKUP_DIR/${backup_name}.tar.gz"

    log_debug "Backing up GRUB configuration"

    local grub_files=()
    [[ -f /etc/default/grub ]] && grub_files+=("/etc/default/grub")
    [[ -d /etc/grub.d ]] && grub_files+=("/etc/grub.d")
    [[ -f /boot/grub/grub.cfg ]] && grub_files+=("/boot/grub/grub.cfg")
    [[ -f /boot/grub2/grub.cfg ]] && grub_files+=("/boot/grub2/grub.cfg")

    if [[ ${#grub_files[@]} -gt 0 ]]; then
        run_as_root tar -czf "$backup_path" "${grub_files[@]}" 2>/dev/null
        log_info "GRUB backup created: $backup_path"
        return 0
    else
        log_warn "No GRUB files found to backup"
        return 1
    fi
}

# List available backups
module_list_backups() {
    local backups=()

    if [[ -d "$BACKUP_DIR" ]]; then
        while IFS= read -r -d '' file; do
            backups+=("$file")
        done < <(find "$BACKUP_DIR" -maxdepth 1 -type f \( -name "*.tar.gz" -o -name "*.txt" \) -print0 2>/dev/null | sort -z)
    fi

    echo "${backups[@]}"
}

# Restore from backup
module_restore_backup() {
    local backup_file="$1"

    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi

    log_info "Restoring from backup: $backup_file"

    case "$backup_file" in
        *.tar.gz)
            _restore_tar_backup "$backup_file"
            ;;
        *.txt)
            _restore_package_list "$backup_file"
            ;;
        *)
            log_error "Unknown backup format"
            return 1
            ;;
    esac

    return 0
}

# Restore tar backup
_restore_tar_backup() {
    local backup_file="$1"

    log_debug "Restoring tar backup: $backup_file"

    if [[ "$backup_file" == *"home_backup"* ]]; then
        tar -xzf "$backup_file" -C "$HOME" 2>/dev/null
    elif [[ "$backup_file" == *"config_backup"* ]]; then
        tar -xzf "$backup_file" -C "$HOME" 2>/dev/null
    elif [[ "$backup_file" == *"system_backup"* ]]; then
        run_as_root tar -xzf "$backup_file" -C / 2>/dev/null
    elif [[ "$backup_file" == *"grub_backup"* ]]; then
        run_as_root tar -xzf "$backup_file" -C / 2>/dev/null
    else
        log_warn "Cannot determine restore location for: $backup_file"
        return 1
    fi

    log_info "Backup restored successfully"
    return 0
}

# Restore package list
_restore_package_list() {
    local backup_file="$1"

    log_debug "Restoring package list from: $backup_file"

    case "$PKG_MANAGER" in
        apt)
            run_as_root dpkg --set-selections < "$backup_file"
            run_as_root apt-get dselect-upgrade -y
            ;;
        dnf)
            run_as_root dnf install -y $(cat "$backup_file")
            ;;
        pacman)
            run_as_root pacman -S --needed --noconfirm $(cat "$backup_file" | awk '{print $1}')
            ;;
        *)
            log_warn "Package restoration not supported for $PKG_MANAGER"
            return 1
            ;;
    esac

    return 0
}

# ============================================================================
# PACKAGE MANAGER REPAIR
# ============================================================================

# Full package manager repair
repair_package_manager() {
    log_info "Repairing package manager: $PKG_MANAGER"

    case "$PKG_MANAGER" in
        apt)
            _repair_apt
            ;;
        dnf)
            _repair_dnf
            ;;
        pacman)
            _repair_pacman
            ;;
        zypper)
            _repair_zypper
            ;;
        *)
            log_error "Package manager repair not supported for: $PKG_MANAGER"
            return 1
            ;;
    esac

    log_info "Package manager repair complete"
    return 0
}

# Repair APT (Debian/Ubuntu)
_repair_apt() {
    log_debug "Repairing APT package manager"

    # Kill any stuck processes
    run_as_root killall -9 apt apt-get dpkg 2>/dev/null || true

    # Remove lock files
    run_as_root rm -f /var/lib/apt/lists/lock 2>/dev/null
    run_as_root rm -f /var/cache/apt/archives/lock 2>/dev/null
    run_as_root rm -f /var/lib/dpkg/lock* 2>/dev/null

    # Configure pending packages
    log_debug "Configuring pending packages..."
    run_as_root dpkg --configure -a

    # Fix broken dependencies
    log_debug "Fixing broken dependencies..."
    run_as_root apt --fix-broken install -y

    # Update package lists
    log_debug "Updating package lists..."
    run_as_root apt update

    # Clean up
    log_debug "Cleaning up..."
    run_as_root apt autoremove -y
    run_as_root apt autoclean

    return 0
}

# Repair DNF (Fedora/RHEL)
_repair_dnf() {
    log_debug "Repairing DNF package manager"

    # Clean all caches
    run_as_root dnf clean all

    # Rebuild cache
    run_as_root dnf makecache

    # Check for problems
    run_as_root dnf check

    # Distro sync
    log_debug "Running distro-sync..."
    run_as_root dnf distro-sync -y

    # Autoremove unused packages
    run_as_root dnf autoremove -y

    return 0
}

# Repair Pacman (Arch)
_repair_pacman() {
    log_debug "Repairing Pacman package manager"

    # Remove lock file
    run_as_root rm -f /var/lib/pacman/db.lck 2>/dev/null

    # Update keyring
    log_debug "Updating keyring..."
    run_as_root pacman -Sy --noconfirm archlinux-keyring 2>/dev/null || true

    # Force refresh
    log_debug "Refreshing package database..."
    run_as_root pacman -Syy

    # Check for package issues
    run_as_root pacman -Dk 2>/dev/null || true

    return 0
}

# Repair Zypper (openSUSE)
_repair_zypper() {
    log_debug "Repairing Zypper package manager"

    # Clean caches
    run_as_root zypper clean --all

    # Refresh repositories
    run_as_root zypper refresh

    # Verify system
    run_as_root zypper verify

    return 0
}

# ============================================================================
# INITRAMFS MANAGEMENT
# ============================================================================

# Regenerate initramfs
regenerate_initramfs() {
    log_info "Regenerating initramfs..."

    local kernel_version="${1:-$(uname -r)}"

    # Detect initramfs tool
    if have_cmd update-initramfs; then
        _regenerate_initramfs_debian "$kernel_version"
    elif have_cmd dracut; then
        _regenerate_initramfs_dracut "$kernel_version"
    elif have_cmd mkinitcpio; then
        _regenerate_initramfs_arch "$kernel_version"
    else
        log_error "No initramfs tool found"
        return 1
    fi

    return 0
}

# Regenerate using update-initramfs (Debian/Ubuntu)
_regenerate_initramfs_debian() {
    local kernel_version="$1"

    log_debug "Using update-initramfs for kernel $kernel_version"

    run_as_root update-initramfs -u -k "$kernel_version"

    if [[ $? -eq 0 ]]; then
        log_info "initramfs regenerated successfully"
        return 0
    else
        log_error "Failed to regenerate initramfs"
        return 1
    fi
}

# Regenerate using dracut (Fedora/RHEL/openSUSE)
_regenerate_initramfs_dracut() {
    local kernel_version="$1"

    log_debug "Using dracut for kernel $kernel_version"

    run_as_root dracut --force --kver "$kernel_version"

    if [[ $? -eq 0 ]]; then
        log_info "initramfs regenerated successfully"
        return 0
    else
        log_error "Failed to regenerate initramfs"
        return 1
    fi
}

# Regenerate using mkinitcpio (Arch)
_regenerate_initramfs_arch() {
    local kernel_version="$1"

    log_debug "Using mkinitcpio for kernel $kernel_version"

    # Generate for specific kernel or all
    if [[ "$kernel_version" == "$(uname -r)" ]]; then
        run_as_root mkinitcpio -P
    else
        run_as_root mkinitcpio -k "$kernel_version" -g "/boot/initramfs-${kernel_version}.img"
    fi

    if [[ $? -eq 0 ]]; then
        log_info "initramfs regenerated successfully"
        return 0
    else
        log_error "Failed to regenerate initramfs"
        return 1
    fi
}

# List available kernels
list_available_kernels() {
    local kernels=()

    if [[ -d /lib/modules ]]; then
        for dir in /lib/modules/*/; do
            if [[ -d "$dir" ]]; then
                local version
                version=$(basename "$dir")
                kernels+=("$version")
            fi
        done
    fi

    echo "${kernels[@]}"
}

# ============================================================================
# DKMS MANAGEMENT
# ============================================================================

# Rebuild all DKMS modules
rebuild_all_dkms() {
    if ! have_cmd dkms; then
        log_error "DKMS is not installed"
        return 1
    fi

    local kernel_version="${1:-$(uname -r)}"

    log_info "Rebuilding DKMS modules for kernel $kernel_version"

    # Get list of installed DKMS modules
    local modules
    modules=$(dkms status 2>/dev/null | grep -oP '^[^,]+' | sort -u)

    if [[ -z "$modules" ]]; then
        log_info "No DKMS modules found"
        return 0
    fi

    local success=0
    local failed=0

    for mod in $modules; do
        local name version
        name=$(echo "$mod" | cut -d'/' -f1)
        version=$(echo "$mod" | cut -d'/' -f2 | cut -d',' -f1)

        log_debug "Rebuilding: $name/$version"

        # Remove and reinstall
        run_as_root dkms remove "$name/$version" -k "$kernel_version" 2>/dev/null || true
        if run_as_root dkms install "$name/$version" -k "$kernel_version" 2>/dev/null; then
            ((success++))
        else
            log_warn "Failed to rebuild: $name"
            ((failed++))
        fi
    done

    log_info "DKMS rebuild complete: $success succeeded, $failed failed"
    return 0
}

# Check DKMS status
check_dkms_status() {
    if ! have_cmd dkms; then
        echo "DKMS not installed"
        return 1
    fi

    dkms status 2>/dev/null
}

# ============================================================================
# BOOTLOADER (GRUB) MANAGEMENT
# ============================================================================

# Update GRUB configuration
update_grub_config() {
    log_info "Updating GRUB configuration"

    if have_cmd update-grub; then
        # Debian/Ubuntu
        run_as_root update-grub
    elif have_cmd grub2-mkconfig; then
        # Fedora/RHEL
        if [[ -f /boot/grub2/grub.cfg ]]; then
            run_as_root grub2-mkconfig -o /boot/grub2/grub.cfg
        elif [[ -d /boot/efi/EFI ]]; then
            # UEFI system
            local grub_cfg
            grub_cfg=$(find /boot/efi/EFI -name "grub.cfg" 2>/dev/null | head -1)
            if [[ -n "$grub_cfg" ]]; then
                run_as_root grub2-mkconfig -o "$grub_cfg"
            fi
        fi
    elif have_cmd grub-mkconfig; then
        # Arch/Generic
        if [[ -f /boot/grub/grub.cfg ]]; then
            run_as_root grub-mkconfig -o /boot/grub/grub.cfg
        fi
    else
        log_error "No GRUB configuration tool found"
        return 1
    fi

    log_info "GRUB configuration updated"
    return 0
}

# Reinstall GRUB bootloader
reinstall_grub() {
    local device="${1:-}"

    if [[ -z "$device" ]]; then
        # Try to detect boot device
        device=$(get_boot_device)
        if [[ -z "$device" ]]; then
            log_error "Could not detect boot device. Please specify manually."
            return 1
        fi
    fi

    log_info "Reinstalling GRUB to $device"

    # Check if UEFI or BIOS
    if [[ -d /sys/firmware/efi ]]; then
        _reinstall_grub_uefi
    else
        _reinstall_grub_bios "$device"
    fi

    return $?
}

# Reinstall GRUB for BIOS systems
_reinstall_grub_bios() {
    local device="$1"

    log_debug "Reinstalling GRUB (BIOS) to $device"

    if have_cmd grub-install; then
        run_as_root grub-install "$device"
    elif have_cmd grub2-install; then
        run_as_root grub2-install "$device"
    else
        log_error "grub-install not found"
        return 1
    fi

    update_grub_config
    return 0
}

# Reinstall GRUB for UEFI systems
_reinstall_grub_uefi() {
    log_debug "Reinstalling GRUB (UEFI)"

    # Detect EFI directory
    local efi_dir=""
    if [[ -d /boot/efi/EFI ]]; then
        efi_dir="/boot/efi"
    elif [[ -d /boot/EFI ]]; then
        efi_dir="/boot"
    else
        log_error "EFI directory not found"
        return 1
    fi

    if have_cmd grub-install; then
        run_as_root grub-install --target=x86_64-efi --efi-directory="$efi_dir" --bootloader-id=GRUB
    elif have_cmd grub2-install; then
        run_as_root grub2-install --target=x86_64-efi --efi-directory="$efi_dir" --bootloader-id=GRUB
    else
        log_error "grub-install not found"
        return 1
    fi

    update_grub_config
    return 0
}

# Get boot device
get_boot_device() {
    local root_part
    root_part=$(findmnt -n -o SOURCE /)

    if [[ -n "$root_part" ]]; then
        # Remove partition number to get device
        echo "$root_part" | sed 's/[0-9]*$//' | sed 's/p$//'
    fi
}

# Check GRUB configuration
check_grub_config() {
    local info=""

    info+="GRUB Configuration Check\n"
    info+="========================\n\n"

    # Boot mode
    if [[ -d /sys/firmware/efi ]]; then
        info+="Boot Mode: UEFI\n"
    else
        info+="Boot Mode: BIOS/Legacy\n"
    fi

    # GRUB config location
    if [[ -f /boot/grub/grub.cfg ]]; then
        info+="Config: /boot/grub/grub.cfg\n"
    elif [[ -f /boot/grub2/grub.cfg ]]; then
        info+="Config: /boot/grub2/grub.cfg\n"
    else
        info+="Config: Not found\n"
    fi

    # Default entry
    if [[ -f /etc/default/grub ]]; then
        local default_entry
        default_entry=$(grep "^GRUB_DEFAULT=" /etc/default/grub 2>/dev/null | cut -d'=' -f2)
        info+="Default: ${default_entry:-0}\n"

        local timeout
        timeout=$(grep "^GRUB_TIMEOUT=" /etc/default/grub 2>/dev/null | cut -d'=' -f2)
        info+="Timeout: ${timeout:-5} seconds\n"
    fi

    # Boot device
    local boot_dev
    boot_dev=$(get_boot_device)
    info+="Boot Device: ${boot_dev:-Unknown}\n"

    echo -e "$info"
}

# ============================================================================
# NETWORKING REPAIR
# ============================================================================

# Full network repair
repair_networking() {
    log_info "Repairing networking configuration"

    # Restart NetworkManager
    _restart_network_service

    # Flush DNS cache
    _flush_dns_cache

    # Reset network configuration
    _reset_network_interfaces

    log_info "Network repair complete"
    return 0
}

# Restart network service
_restart_network_service() {
    log_debug "Restarting network service"

    if systemctl is-active NetworkManager &>/dev/null; then
        run_as_root systemctl restart NetworkManager
    elif systemctl is-active systemd-networkd &>/dev/null; then
        run_as_root systemctl restart systemd-networkd
    elif systemctl is-active networking &>/dev/null; then
        run_as_root systemctl restart networking
    else
        log_warn "No known network service found"
    fi
}

# Flush DNS cache
_flush_dns_cache() {
    log_debug "Flushing DNS cache"

    # systemd-resolved
    if systemctl is-active systemd-resolved &>/dev/null; then
        run_as_root systemd-resolve --flush-caches 2>/dev/null || \
        run_as_root resolvectl flush-caches 2>/dev/null || true
    fi

    # nscd
    if have_cmd nscd; then
        run_as_root nscd -i hosts 2>/dev/null || true
    fi

    # dnsmasq
    if systemctl is-active dnsmasq &>/dev/null; then
        run_as_root systemctl restart dnsmasq
    fi
}

# Reset network interfaces
_reset_network_interfaces() {
    log_debug "Resetting network interfaces"

    # Get all network interfaces (excluding lo)
    local interfaces
    interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)

    for iface in $interfaces; do
        # Skip virtual interfaces
        [[ "$iface" == veth* ]] && continue
        [[ "$iface" == docker* ]] && continue
        [[ "$iface" == br-* ]] && continue

        log_debug "Cycling interface: $iface"
        run_as_root ip link set "$iface" down 2>/dev/null || true
        sleep 1
        run_as_root ip link set "$iface" up 2>/dev/null || true
    done
}

# Check network connectivity
check_network_connectivity() {
    local info=""

    info+="Network Connectivity Check\n"
    info+="==========================\n\n"

    # Check interfaces
    info+="Interfaces:\n"
    while IFS= read -r line; do
        local iface state
        iface=$(echo "$line" | awk '{print $1}')
        state=$(echo "$line" | awk '{print $2}')
        [[ "$iface" == "lo:" ]] && continue
        info+="  $iface $state\n"
    done < <(ip -o link show | awk '{print $2, $9}')

    info+="\n"

    # Check DNS
    info+="DNS Resolution:\n"
    if host google.com &>/dev/null; then
        info+="  google.com: OK\n"
    else
        info+="  google.com: FAILED\n"
    fi

    # Check connectivity
    info+="\nInternet Connectivity:\n"
    if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        info+="  8.8.8.8: OK\n"
    else
        info+="  8.8.8.8: FAILED\n"
    fi

    if ping -c 1 -W 2 1.1.1.1 &>/dev/null; then
        info+="  1.1.1.1: OK\n"
    else
        info+="  1.1.1.1: FAILED\n"
    fi

    # DNS servers
    info+="\nConfigured DNS:\n"
    if [[ -f /etc/resolv.conf ]]; then
        while read -r line; do
            if [[ "$line" == nameserver* ]]; then
                info+="  $line\n"
            fi
        done < /etc/resolv.conf
    fi

    echo -e "$info"
}

# ============================================================================
# SYSTEM HEALTH CHECKS
# ============================================================================

# Run full system health check
run_system_health_check() {
    log_info "Running system health check..."

    local report=""
    local warnings=0
    local errors=0

    report+="System Health Report\n"
    report+="====================\n"
    report+="Generated: $(date)\n\n"

    # Disk space
    report+="=== Disk Space ===\n"
    local disk_usage
    disk_usage=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
    if [[ $disk_usage -gt 90 ]]; then
        report+="  Root filesystem: ${disk_usage}% [CRITICAL]\n"
        ((errors++))
    elif [[ $disk_usage -gt 80 ]]; then
        report+="  Root filesystem: ${disk_usage}% [WARNING]\n"
        ((warnings++))
    else
        report+="  Root filesystem: ${disk_usage}% [OK]\n"
    fi

    # Memory
    report+="\n=== Memory ===\n"
    local mem_free
    mem_free=$(free | grep Mem | awk '{printf "%.0f", $7/$2 * 100}')
    if [[ $mem_free -lt 10 ]]; then
        report+="  Available: ${mem_free}% [WARNING]\n"
        ((warnings++))
    else
        report+="  Available: ${mem_free}% [OK]\n"
    fi

    # Swap
    local swap_total
    swap_total=$(free | grep Swap | awk '{print $2}')
    if [[ $swap_total -eq 0 ]]; then
        report+="  Swap: None configured [WARNING]\n"
        ((warnings++))
    else
        report+="  Swap: Configured [OK]\n"
    fi

    # Failed services
    report+="\n=== Systemd Services ===\n"
    local failed_services
    failed_services=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
    if [[ $failed_services -gt 0 ]]; then
        report+="  Failed services: $failed_services [WARNING]\n"
        ((warnings++))
    else
        report+="  All services: OK\n"
    fi

    # Package manager
    report+="\n=== Package Manager ===\n"
    case "$PKG_MANAGER" in
        apt)
            local broken
            broken=$(apt list --installed 2>/dev/null | grep -c "broken" || echo 0)
            if [[ $broken -gt 0 ]]; then
                report+="  Broken packages: $broken [ERROR]\n"
                ((errors++))
            else
                report+="  Packages: OK\n"
            fi
            ;;
        *)
            report+="  Status: Not checked\n"
            ;;
    esac

    # Kernel
    report+="\n=== Kernel ===\n"
    report+="  Running: $(uname -r)\n"

    # DKMS
    if have_cmd dkms; then
        local dkms_issues
        dkms_issues=$(dkms status 2>/dev/null | grep -c "installed" || echo 0)
        report+="  DKMS modules: $dkms_issues\n"
    fi

    # Network
    report+="\n=== Network ===\n"
    if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        report+="  Internet: Connected [OK]\n"
    else
        report+="  Internet: Not connected [WARNING]\n"
        ((warnings++))
    fi

    # Summary
    report+="\n=== Summary ===\n"
    report+="  Errors: $errors\n"
    report+="  Warnings: $warnings\n"

    if [[ $errors -gt 0 ]]; then
        report+="  Status: CRITICAL - Action required\n"
    elif [[ $warnings -gt 0 ]]; then
        report+="  Status: WARNING - Review recommended\n"
    else
        report+="  Status: HEALTHY\n"
    fi

    echo -e "$report"
}

# Check filesystem integrity
check_filesystem_integrity() {
    log_info "Checking filesystem integrity..."

    local info=""

    info+="Filesystem Integrity Check\n"
    info+="==========================\n\n"

    # Check mounted filesystems
    info+="Mounted Filesystems:\n"
    while read -r line; do
        local dev mount fs
        dev=$(echo "$line" | awk '{print $1}')
        mount=$(echo "$line" | awk '{print $2}')
        fs=$(echo "$line" | awk '{print $3}')

        # Skip pseudo filesystems
        [[ "$fs" == "tmpfs" ]] && continue
        [[ "$fs" == "devtmpfs" ]] && continue
        [[ "$fs" == "sysfs" ]] && continue
        [[ "$fs" == "proc" ]] && continue

        info+="  $mount ($fs on $dev)\n"
    done < <(mount | grep "^/")

    info+="\n"

    # Check for read-only mounts (could indicate issues)
    info+="Read-only check:\n"
    if mount | grep -q " / .*ro[,)]"; then
        info+="  Root filesystem: READ-ONLY [CRITICAL]\n"
    else
        info+="  Root filesystem: Read-write [OK]\n"
    fi

    # Check for filesystem errors in dmesg
    info+="\nRecent filesystem errors:\n"
    local fs_errors
    fs_errors=$(dmesg 2>/dev/null | grep -iE "ext[234]|xfs|btrfs" | grep -i error | tail -5)
    if [[ -n "$fs_errors" ]]; then
        info+="$fs_errors\n"
    else
        info+="  No recent errors found\n"
    fi

    echo -e "$info"
}

# ============================================================================
# SYSTEM CLEANUP
# ============================================================================

# Clean system
module_clean_system() {
    log_info "Cleaning system"

    # Clean package cache
    if declare -f pkg_clean &>/dev/null; then
        pkg_clean
    fi

    # Clean temp files
    rm -rf /tmp/suite.* 2>/dev/null

    # Clean user cache (old files only)
    if [[ -d "$HOME/.cache" ]]; then
        find "$HOME/.cache" -type f -atime +30 -delete 2>/dev/null
    fi

    # Clean journal logs
    if have_cmd journalctl; then
        run_as_root journalctl --vacuum-time=7d 2>/dev/null
    fi

    log_info "System cleanup complete"
    return 0
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Get backup directory path
get_backup_dir() {
    echo "$BACKUP_DIR"
}

# Set backup directory path
set_backup_dir() {
    local new_dir="$1"

    if [[ -d "$new_dir" ]] || mkdir -p "$new_dir" 2>/dev/null; then
        BACKUP_DIR="$new_dir"
        log_debug "Backup directory set to: $BACKUP_DIR"
        return 0
    else
        log_error "Cannot set backup directory: $new_dir"
        return 1
    fi
}

# Get recovery log
get_recovery_log() {
    echo "$RECOVERY_LOG"
}
