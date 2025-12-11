#!/usr/bin/env bash
#
# recovery_menu.sh - Recovery & Tools Menu for Ultimate Linux Suite
#
# Provides system recovery, backup, repair, and maintenance tools
#

# Prevent multiple sourcing
[[ -n "${_RECOVERY_MENU_SH_LOADED:-}" ]] && return 0
readonly _RECOVERY_MENU_SH_LOADED=1

# ============================================================================
# MAIN RECOVERY MENU
# ============================================================================

run_recovery_menu() {
    local choice

    # Initialize recovery module
    if declare -f module_recovery_init &>/dev/null; then
        module_recovery_init
    fi

    while true; do
        choice=$(menu_select "Recovery & Tools" \
            "System recovery and maintenance:" \
            "health"     "System Health Check" \
            "repair"     "Repair Tools" \
            "backup"     "Backup Manager" \
            "restore"    "Restore System" \
            "bootloader" "Bootloader Tools" \
            "network"    "Network Repair" \
            "disk"       "Disk Utilities" \
            "logs"       "System Logs" \
            "back"       "Back to Main Menu")

        case "$choice" in
            health)
                run_health_check_menu
                ;;
            repair)
                run_repair_menu
                ;;
            backup)
                run_backup_menu
                ;;
            restore)
                run_restore_menu
                ;;
            bootloader)
                run_bootloader_menu
                ;;
            network)
                run_network_repair_menu
                ;;
            disk)
                run_disk_menu
                ;;
            logs)
                run_logs_menu
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# ============================================================================
# SYSTEM HEALTH CHECK
# ============================================================================

run_health_check_menu() {
    local choice

    while true; do
        choice=$(menu_select "System Health" \
            "System health checks and diagnostics:" \
            "full"      "Full Health Check" \
            "disk"      "Disk Space Check" \
            "memory"    "Memory Check" \
            "services"  "Failed Services" \
            "fs"        "Filesystem Integrity" \
            "back"      "Back")

        case "$choice" in
            full)
                run_full_health_check
                ;;
            disk)
                check_disk_space
                ;;
            memory)
                check_memory_status
                ;;
            services)
                check_failed_services
                ;;
            fs)
                check_fs_integrity
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# Run full health check
run_full_health_check() {
    show_wait "Running system health check..."

    local report=""

    if declare -f run_system_health_check &>/dev/null; then
        report=$(run_system_health_check)
    else
        report="Health check module not loaded."
    fi

    local tmpfile
    tmpfile=$(make_temp "health")
    echo -e "$report" > "$tmpfile"

    textbox "System Health Report" "$tmpfile"
    rm -f "$tmpfile"
}

# Check disk space
check_disk_space() {
    local info=""

    info+="Disk Space Usage\n"
    info+="================\n\n"

    while read -r line; do
        local usage mount
        usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        mount=$(echo "$line" | awk '{print $6}')

        if [[ $usage -gt 90 ]]; then
            info+="[CRITICAL] $line\n"
        elif [[ $usage -gt 80 ]]; then
            info+="[WARNING]  $line\n"
        else
            info+="[OK]       $line\n"
        fi
    done < <(df -h | grep "^/")

    message_box "Disk Space" "$info"
}

# Check memory status
check_memory_status() {
    local info=""

    info+="Memory Status\n"
    info+="=============\n\n"

    local mem_info
    mem_info=$(free -h)
    info+="$mem_info\n\n"

    # Calculate available percentage
    local mem_avail_pct
    mem_avail_pct=$(free | grep Mem | awk '{printf "%.1f", $7/$2 * 100}')
    info+="Available: ${mem_avail_pct}%\n"

    if (( $(echo "$mem_avail_pct < 10" | bc -l 2>/dev/null || echo 0) )); then
        info+="\n[WARNING] Low memory available"
    fi

    message_box "Memory Status" "$info"
}

# Check failed services
check_failed_services() {
    local failed
    failed=$(systemctl --failed --no-legend 2>/dev/null)

    if [[ -z "$failed" ]]; then
        message_box "Services" "No failed services detected.\n\nAll systemd services are running normally."
    else
        local tmpfile
        tmpfile=$(make_temp "services")

        echo "Failed Systemd Services" > "$tmpfile"
        echo "=======================" >> "$tmpfile"
        echo "" >> "$tmpfile"
        echo "$failed" >> "$tmpfile"
        echo "" >> "$tmpfile"
        echo "To investigate, run: systemctl status <service-name>" >> "$tmpfile"

        textbox "Failed Services" "$tmpfile"
        rm -f "$tmpfile"
    fi
}

# Check filesystem integrity
check_fs_integrity() {
    show_wait "Checking filesystem integrity..."

    local info=""

    if declare -f check_filesystem_integrity &>/dev/null; then
        info=$(check_filesystem_integrity)
    else
        info="Filesystem: $(df -T / | tail -1 | awk '{print $2}')\n"
        info+="Mount status: $(mount | grep ' / ' | awk '{print $6}')\n"
    fi

    message_box "Filesystem Integrity" "$info"
}

# ============================================================================
# REPAIR TOOLS
# ============================================================================

run_repair_menu() {
    local choice

    while true; do
        choice=$(menu_select "Repair Tools" \
            "System repair utilities:" \
            "pkgmgr"    "Repair Package Manager" \
            "initramfs" "Regenerate Initramfs" \
            "dkms"      "Rebuild DKMS Modules" \
            "perms"     "Fix Home Permissions" \
            "clean"     "System Cleanup" \
            "back"      "Back")

        case "$choice" in
            pkgmgr)
                repair_pkg_manager_interactive
                ;;
            initramfs)
                regenerate_initramfs_interactive
                ;;
            dkms)
                rebuild_dkms_interactive
                ;;
            perms)
                fix_home_permissions
                ;;
            clean)
                run_system_cleanup
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# Repair package manager interactive
repair_pkg_manager_interactive() {
    local pkg_name=""
    case "$PKG_MANAGER" in
        apt) pkg_name="APT (Debian/Ubuntu)" ;;
        dnf) pkg_name="DNF (Fedora)" ;;
        pacman) pkg_name="Pacman (Arch)" ;;
        zypper) pkg_name="Zypper (openSUSE)" ;;
        *) pkg_name="$PKG_MANAGER" ;;
    esac

    if ! yes_no_prompt "Repair Package Manager" \
        "This will repair the $pkg_name package manager.\n\nActions:\n- Remove lock files\n- Configure pending packages\n- Fix broken dependencies\n- Clean package cache\n\nContinue?"; then
        return 0
    fi

    log_info "Repairing package manager: $PKG_MANAGER"

    (
        echo "10"
        echo "XXX"
        echo "Removing lock files..."
        echo "XXX"

        case "$PKG_MANAGER" in
            apt)
                run_as_root rm -f /var/lib/apt/lists/lock 2>/dev/null
                run_as_root rm -f /var/cache/apt/archives/lock 2>/dev/null
                run_as_root rm -f /var/lib/dpkg/lock* 2>/dev/null
                ;;
            pacman)
                run_as_root rm -f /var/lib/pacman/db.lck 2>/dev/null
                ;;
        esac

        echo "30"
        echo "XXX"
        echo "Configuring packages..."
        echo "XXX"

        case "$PKG_MANAGER" in
            apt)
                run_as_root dpkg --configure -a 2>/dev/null
                ;;
        esac

        echo "50"
        echo "XXX"
        echo "Fixing dependencies..."
        echo "XXX"

        if declare -f repair_package_manager &>/dev/null; then
            repair_package_manager 2>/dev/null
        fi

        echo "80"
        echo "XXX"
        echo "Cleaning up..."
        echo "XXX"

        case "$PKG_MANAGER" in
            apt)
                run_as_root apt autoremove -y 2>/dev/null
                run_as_root apt autoclean 2>/dev/null
                ;;
            dnf)
                run_as_root dnf autoremove -y 2>/dev/null
                ;;
        esac

        echo "100"
        echo "XXX"
        echo "Complete!"
        echo "XXX"

    ) | dialog --title "Repairing Package Manager" --gauge "Starting..." 8 60 0

    message_box "Complete" "Package manager repair finished.\n\nIf problems persist, try running the repair again\nor check system logs for errors."
}

# Regenerate initramfs interactive
regenerate_initramfs_interactive() {
    local kernel
    kernel=$(uname -r)

    local tool="Unknown"
    if have_cmd update-initramfs; then
        tool="update-initramfs"
    elif have_cmd dracut; then
        tool="dracut"
    elif have_cmd mkinitcpio; then
        tool="mkinitcpio"
    fi

    if ! yes_no_prompt "Regenerate Initramfs" \
        "Regenerate the initial ramdisk for the current kernel?\n\nKernel: $kernel\nTool: $tool\n\nThis is useful after:\n- Installing new drivers\n- Changing kernel modules\n- Recovering from boot issues\n\nContinue?"; then
        return 0
    fi

    log_info "Regenerating initramfs for kernel $kernel"
    show_wait "Regenerating initramfs..."

    if declare -f regenerate_initramfs &>/dev/null; then
        if regenerate_initramfs "$kernel"; then
            message_box "Success" "Initramfs regenerated successfully for kernel $kernel."
        else
            message_box "Error" "Failed to regenerate initramfs.\nCheck system logs for details."
        fi
    else
        message_box "Error" "Initramfs regeneration function not available."
    fi
}

# Rebuild DKMS modules interactive
rebuild_dkms_interactive() {
    if ! have_cmd dkms; then
        message_box "DKMS" "DKMS is not installed on this system.\n\nInstall with:\n  apt install dkms\n  dnf install dkms\n  pacman -S dkms"
        return 0
    fi

    local kernel
    kernel=$(uname -r)

    local modules
    modules=$(dkms status 2>/dev/null | wc -l)

    if ! yes_no_prompt "Rebuild DKMS" \
        "Rebuild all DKMS modules for the current kernel?\n\nKernel: $kernel\nModules: $modules registered\n\nThis is useful after:\n- Kernel updates\n- Driver issues\n- Module compilation failures\n\nContinue?"; then
        return 0
    fi

    log_info "Rebuilding DKMS modules"
    show_wait "Rebuilding DKMS modules..."

    if declare -f rebuild_all_dkms &>/dev/null; then
        rebuild_all_dkms "$kernel"
    elif declare -f rebuild_dkms_modules &>/dev/null; then
        rebuild_dkms_modules
    fi

    message_box "Complete" "DKMS module rebuild finished.\n\nCheck system logs if any modules failed."
}

# Fix home permissions
fix_home_permissions() {
    if ! yes_no_prompt "Fix Permissions" \
        "Reset ownership and permissions on your home directory?\n\nThis will:\n- Set ownership to $USER:$USER\n- Fix common permission issues\n\nContinue?"; then
        return 0
    fi

    log_info "Fixing home directory permissions"
    show_wait "Fixing permissions..."

    run_as_root chown -R "$USER:$USER" "$HOME"
    chmod 700 "$HOME"
    chmod 700 "$HOME/.ssh" 2>/dev/null || true
    chmod 600 "$HOME/.ssh/"* 2>/dev/null || true

    message_box "Complete" "Home directory permissions have been reset."
}

# Run system cleanup
run_system_cleanup() {
    if ! yes_no_prompt "System Cleanup" \
        "Clean temporary files and caches?\n\nThis will:\n- Clean package manager cache\n- Remove old temp files\n- Trim journal logs\n\nContinue?"; then
        return 0
    fi

    log_info "Running system cleanup"
    show_wait "Cleaning system..."

    if declare -f module_clean_system &>/dev/null; then
        module_clean_system
    fi

    message_box "Complete" "System cleanup finished."
}

# ============================================================================
# BACKUP MANAGER
# ============================================================================

run_backup_menu() {
    local choice

    while true; do
        local backup_dir
        backup_dir=$(get_backup_dir 2>/dev/null || echo "$HOME/.suite-backups")

        choice=$(menu_select "Backup Manager" \
            "Backup directory: $backup_dir" \
            "config"    "Backup Configurations" \
            "packages"  "Backup Package List" \
            "system"    "Backup System Files" \
            "grub"      "Backup GRUB Config" \
            "list"      "List Backups" \
            "back"      "Back")

        case "$choice" in
            config)
                backup_configs_interactive
                ;;
            packages)
                backup_packages_interactive
                ;;
            system)
                backup_system_interactive
                ;;
            grub)
                backup_grub_interactive
                ;;
            list)
                list_backups_interactive
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# Backup configurations interactive
backup_configs_interactive() {
    if ! yes_no_prompt "Backup Configs" "Backup user configuration files?\n\nIncludes:\n- .bashrc, .zshrc, .profile\n- .config directory\n- Desktop entries"; then
        return 0
    fi

    log_info "Backing up configurations"
    show_wait "Creating configuration backup..."

    if declare -f module_create_backup &>/dev/null && module_create_backup "config"; then
        local backup_dir
        backup_dir=$(get_backup_dir 2>/dev/null || echo "$HOME/.suite-backups")
        message_box "Success" "Configuration backup created in:\n$backup_dir"
    else
        message_box "Error" "Failed to create backup."
    fi
}

# Backup packages interactive
backup_packages_interactive() {
    if ! yes_no_prompt "Backup Packages" "Export list of installed packages?\n\nThis creates a text file that can be used\nto reinstall packages on a fresh system."; then
        return 0
    fi

    log_info "Backing up package list"
    show_wait "Exporting package list..."

    if declare -f module_create_backup &>/dev/null && module_create_backup "packages"; then
        local backup_dir
        backup_dir=$(get_backup_dir 2>/dev/null || echo "$HOME/.suite-backups")
        message_box "Success" "Package list exported to:\n$backup_dir"
    else
        message_box "Error" "Failed to export package list."
    fi
}

# Backup system interactive
backup_system_interactive() {
    if ! yes_no_prompt "Backup System" "Backup system configuration files?\n\nIncludes:\n- /etc/fstab\n- /etc/default/grub\n- /etc/modprobe.d\n- /etc/sysctl.conf\n- /etc/sysctl.d\n- /etc/NetworkManager\n\nRequires root privileges."; then
        return 0
    fi

    log_info "Backing up system files"
    show_wait "Creating system backup..."

    if declare -f module_create_backup &>/dev/null && module_create_backup "system"; then
        local backup_dir
        backup_dir=$(get_backup_dir 2>/dev/null || echo "$HOME/.suite-backups")
        message_box "Success" "System backup created in:\n$backup_dir"
    else
        message_box "Error" "Failed to create system backup."
    fi
}

# Backup GRUB interactive
backup_grub_interactive() {
    if ! yes_no_prompt "Backup GRUB" "Backup GRUB bootloader configuration?\n\nIncludes:\n- /etc/default/grub\n- /etc/grub.d/\n- grub.cfg"; then
        return 0
    fi

    log_info "Backing up GRUB"
    show_wait "Creating GRUB backup..."

    if declare -f module_create_backup &>/dev/null && module_create_backup "grub"; then
        local backup_dir
        backup_dir=$(get_backup_dir 2>/dev/null || echo "$HOME/.suite-backups")
        message_box "Success" "GRUB backup created in:\n$backup_dir"
    else
        message_box "Error" "Failed to create GRUB backup."
    fi
}

# List backups interactive
list_backups_interactive() {
    local backup_dir
    backup_dir=$(get_backup_dir 2>/dev/null || echo "$HOME/.suite-backups")

    if [[ ! -d "$backup_dir" ]]; then
        message_box "Backups" "No backup directory found.\n\nCreate a backup first."
        return 0
    fi

    local backups
    backups=$(find "$backup_dir" -maxdepth 1 -type f \( -name "*.tar.gz" -o -name "*.txt" \) 2>/dev/null | sort)

    if [[ -z "$backups" ]]; then
        message_box "Backups" "No backups found in:\n$backup_dir"
        return 0
    fi

    local tmpfile
    tmpfile=$(make_temp "backups")

    echo "Available Backups" > "$tmpfile"
    echo "=================" >> "$tmpfile"
    echo "" >> "$tmpfile"
    echo "Directory: $backup_dir" >> "$tmpfile"
    echo "" >> "$tmpfile"

    while IFS= read -r file; do
        local filename size date
        filename=$(basename "$file")
        size=$(ls -lh "$file" | awk '{print $5}')
        date=$(ls -l "$file" | awk '{print $6, $7, $8}')
        echo "  $filename ($size) - $date" >> "$tmpfile"
    done <<< "$backups"

    textbox "Available Backups" "$tmpfile"
    rm -f "$tmpfile"
}

# ============================================================================
# RESTORE SYSTEM
# ============================================================================

run_restore_menu() {
    local choice

    while true; do
        choice=$(menu_select "Restore System" \
            "Restore from backup:" \
            "select"    "Select Backup to Restore" \
            "packages"  "Restore Package List" \
            "back"      "Back")

        case "$choice" in
            select)
                select_restore_backup
                ;;
            packages)
                restore_packages_interactive
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# Select and restore backup
select_restore_backup() {
    local backup_dir
    backup_dir=$(get_backup_dir 2>/dev/null || echo "$HOME/.suite-backups")

    if [[ ! -d "$backup_dir" ]]; then
        message_box "Restore" "No backup directory found."
        return 0
    fi

    # Get list of backups
    local -a backup_files=()
    local -a menu_items=()

    while IFS= read -r -d '' file; do
        backup_files+=("$file")
        local filename
        filename=$(basename "$file")
        menu_items+=("$filename" "$(ls -lh "$file" | awk '{print $5}')")
    done < <(find "$backup_dir" -maxdepth 1 -type f \( -name "*.tar.gz" -o -name "*.txt" \) -print0 2>/dev/null | sort -z)

    if [[ ${#backup_files[@]} -eq 0 ]]; then
        message_box "Restore" "No backups found."
        return 0
    fi

    local selected
    selected=$(menu_select "Select Backup" "Choose a backup to restore:" "${menu_items[@]}" "back" "Cancel")

    if [[ "$selected" == "back" ]] || [[ -z "$selected" ]]; then
        return 0
    fi

    local backup_path="$backup_dir/$selected"

    if yes_no_prompt "Confirm Restore" "Restore from backup:\n\n$selected\n\nThis may overwrite existing files. Continue?"; then
        log_info "Restoring from: $backup_path"
        show_wait "Restoring backup..."

        if declare -f module_restore_backup &>/dev/null && module_restore_backup "$backup_path"; then
            message_box "Success" "Backup restored successfully."
        else
            message_box "Error" "Failed to restore backup."
        fi
    fi
}

# Restore packages interactive
restore_packages_interactive() {
    message_box "Restore Packages" "To restore packages from a backup:\n\n1. Locate your package list backup (.txt file)\n2. Run the appropriate command:\n\n   APT: sudo dpkg --set-selections < backup.txt\n        sudo apt-get dselect-upgrade\n\n   DNF: sudo dnf install \$(cat backup.txt)\n\n   Pacman: sudo pacman -S --needed \$(cat backup.txt)"
}

# ============================================================================
# BOOTLOADER TOOLS
# ============================================================================

run_bootloader_menu() {
    local choice

    while true; do
        choice=$(menu_select "Bootloader Tools" \
            "GRUB bootloader management:" \
            "status"    "Check GRUB Status" \
            "update"    "Update GRUB Config" \
            "reinstall" "Reinstall GRUB" \
            "backup"    "Backup GRUB" \
            "back"      "Back")

        case "$choice" in
            status)
                show_grub_status
                ;;
            update)
                update_grub_interactive
                ;;
            reinstall)
                reinstall_grub_interactive
                ;;
            backup)
                backup_grub_interactive
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# Show GRUB status
show_grub_status() {
    local info=""

    if declare -f check_grub_config &>/dev/null; then
        info=$(check_grub_config)
    else
        info="GRUB Status\n===========\n\n"

        if [[ -d /sys/firmware/efi ]]; then
            info+="Boot Mode: UEFI\n"
        else
            info+="Boot Mode: BIOS/Legacy\n"
        fi

        if [[ -f /etc/default/grub ]]; then
            info+="Config: /etc/default/grub exists\n"
        fi
    fi

    message_box "GRUB Status" "$info"
}

# Update GRUB interactive
update_grub_interactive() {
    if ! have_cmd grub-mkconfig && ! have_cmd update-grub && ! have_cmd grub2-mkconfig; then
        message_box "GRUB" "GRUB utilities not found on this system."
        return 0
    fi

    if ! yes_no_prompt "Update GRUB" "Update GRUB configuration?\n\nThis regenerates grub.cfg from /etc/default/grub."; then
        return 0
    fi

    log_info "Updating GRUB configuration"
    show_wait "Updating GRUB..."

    if declare -f update_grub_config &>/dev/null && update_grub_config; then
        message_box "Success" "GRUB configuration updated."
    else
        message_box "Error" "Failed to update GRUB configuration."
    fi
}

# Reinstall GRUB interactive
reinstall_grub_interactive() {
    local boot_dev=""

    if declare -f get_boot_device &>/dev/null; then
        boot_dev=$(get_boot_device)
    fi

    local boot_mode="BIOS"
    [[ -d /sys/firmware/efi ]] && boot_mode="UEFI"

    if ! yes_no_prompt "Reinstall GRUB" \
        "Reinstall the GRUB bootloader?\n\nBoot mode: $boot_mode\nDetected device: ${boot_dev:-Unknown}\n\nWARNING: Incorrect bootloader installation\ncan make your system unbootable.\n\nContinue?"; then
        return 0
    fi

    log_info "Reinstalling GRUB"
    show_wait "Reinstalling GRUB bootloader..."

    if declare -f reinstall_grub &>/dev/null && reinstall_grub "$boot_dev"; then
        message_box "Success" "GRUB bootloader reinstalled.\n\nIf the system fails to boot, you may need to\nuse a live USB to repair the bootloader."
    else
        message_box "Error" "Failed to reinstall GRUB.\n\nCheck system logs for details."
    fi
}

# ============================================================================
# NETWORK REPAIR
# ============================================================================

run_network_repair_menu() {
    local choice

    while true; do
        choice=$(menu_select "Network Repair" \
            "Network troubleshooting:" \
            "status"    "Network Status" \
            "repair"    "Full Network Repair" \
            "restart"   "Restart Network Service" \
            "dns"       "Flush DNS Cache" \
            "back"      "Back")

        case "$choice" in
            status)
                show_network_status
                ;;
            repair)
                full_network_repair
                ;;
            restart)
                restart_network_service
                ;;
            dns)
                flush_dns_interactive
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# Show network status
show_network_status() {
    local info=""

    if declare -f check_network_connectivity &>/dev/null; then
        info=$(check_network_connectivity)
    else
        info="Network Status\n==============\n\n"
        info+="$(ip -o link show | awk '{print $2, $9}')\n"
    fi

    message_box "Network Status" "$info"
}

# Full network repair
full_network_repair() {
    if ! yes_no_prompt "Network Repair" \
        "Run full network repair?\n\nThis will:\n- Restart network services\n- Flush DNS cache\n- Cycle network interfaces\n\nContinue?"; then
        return 0
    fi

    log_info "Running network repair"
    show_wait "Repairing network..."

    if declare -f repair_networking &>/dev/null && repair_networking; then
        message_box "Complete" "Network repair finished.\n\nCheck connectivity with the status option."
    else
        message_box "Error" "Network repair encountered issues."
    fi
}

# Restart network service
restart_network_service() {
    if ! yes_no_prompt "Restart Network" "Restart network services?"; then
        return 0
    fi

    log_info "Restarting network services"
    show_wait "Restarting network..."

    if systemctl is-active NetworkManager &>/dev/null; then
        run_as_root systemctl restart NetworkManager
    elif systemctl is-active systemd-networkd &>/dev/null; then
        run_as_root systemctl restart systemd-networkd
    else
        run_as_root systemctl restart networking 2>/dev/null || true
    fi

    message_box "Complete" "Network services restarted."
}

# Flush DNS cache
flush_dns_interactive() {
    log_info "Flushing DNS cache"
    show_wait "Flushing DNS cache..."

    if systemctl is-active systemd-resolved &>/dev/null; then
        run_as_root resolvectl flush-caches 2>/dev/null || \
        run_as_root systemd-resolve --flush-caches 2>/dev/null
    fi

    if have_cmd nscd; then
        run_as_root nscd -i hosts 2>/dev/null || true
    fi

    message_box "Complete" "DNS cache flushed."
}

# ============================================================================
# DISK UTILITIES
# ============================================================================

run_disk_menu() {
    local choice

    while true; do
        choice=$(menu_select "Disk Utilities" \
            "Disk management tools:" \
            "usage"     "Disk Usage" \
            "smart"     "SMART Status" \
            "trim"      "Run TRIM (SSD)" \
            "back"      "Back")

        case "$choice" in
            usage)
                show_disk_usage
                ;;
            smart)
                show_smart_status
                ;;
            trim)
                run_trim_interactive
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# Show disk usage
show_disk_usage() {
    local tmpfile
    tmpfile=$(make_temp "diskusage")

    echo "Disk Usage Summary" > "$tmpfile"
    echo "==================" >> "$tmpfile"
    echo "" >> "$tmpfile"
    df -h >> "$tmpfile" 2>&1

    textbox "Disk Usage" "$tmpfile"
    rm -f "$tmpfile"
}

# Show SMART status
show_smart_status() {
    if ! have_cmd smartctl; then
        message_box "SMART" "smartctl not found.\n\nInstall smartmontools:\n  apt install smartmontools\n  dnf install smartmontools"
        return 0
    fi

    local device
    device=$(findmnt -n -o SOURCE / | sed 's/[0-9]*$//' | sed 's/p$//')

    local tmpfile
    tmpfile=$(make_temp "smart")

    echo "SMART Status for $device" > "$tmpfile"
    echo "=========================" >> "$tmpfile"
    echo "" >> "$tmpfile"
    run_as_root smartctl -H "$device" >> "$tmpfile" 2>&1

    textbox "SMART Status" "$tmpfile"
    rm -f "$tmpfile"
}

# Run TRIM interactive
run_trim_interactive() {
    if ! have_cmd fstrim; then
        message_box "TRIM" "fstrim not found on this system."
        return 0
    fi

    if yes_no_prompt "Run TRIM" "Run TRIM on all mounted filesystems?\n\nTRIM optimizes SSD storage by marking\nunused blocks for garbage collection."; then
        log_info "Running TRIM"
        show_wait "Running TRIM..."

        local output
        output=$(run_as_root fstrim -av 2>&1)

        message_box "TRIM Complete" "$output"
    fi
}

# ============================================================================
# SYSTEM LOGS
# ============================================================================

run_logs_menu() {
    local choice

    while true; do
        choice=$(menu_select "System Logs" \
            "View system logs:" \
            "journal"   "System Journal" \
            "boot"      "Boot Messages" \
            "kernel"    "Kernel Log (dmesg)" \
            "errors"    "Recent Errors" \
            "back"      "Back")

        case "$choice" in
            journal)
                view_system_journal
                ;;
            boot)
                view_boot_log
                ;;
            kernel)
                view_kernel_log
                ;;
            errors)
                view_recent_errors
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# View system journal
view_system_journal() {
    if ! have_cmd journalctl; then
        message_box "Journal" "journalctl not available."
        return 0
    fi

    local tmpfile
    tmpfile=$(make_temp "journal")

    journalctl -n 200 --no-pager > "$tmpfile" 2>&1

    textbox "System Journal (last 200 entries)" "$tmpfile"
    rm -f "$tmpfile"
}

# View boot log
view_boot_log() {
    if ! have_cmd journalctl; then
        message_box "Boot Log" "journalctl not available."
        return 0
    fi

    local tmpfile
    tmpfile=$(make_temp "bootlog")

    journalctl -b --no-pager | tail -300 > "$tmpfile" 2>&1

    textbox "Boot Log (current boot)" "$tmpfile"
    rm -f "$tmpfile"
}

# View kernel log
view_kernel_log() {
    local tmpfile
    tmpfile=$(make_temp "dmesg")

    dmesg | tail -300 > "$tmpfile" 2>&1

    textbox "Kernel Log (dmesg)" "$tmpfile"
    rm -f "$tmpfile"
}

# View recent errors
view_recent_errors() {
    local tmpfile
    tmpfile=$(make_temp "errors")

    echo "Recent System Errors" > "$tmpfile"
    echo "====================" >> "$tmpfile"
    echo "" >> "$tmpfile"

    if have_cmd journalctl; then
        journalctl -p err -n 100 --no-pager >> "$tmpfile" 2>&1
    else
        dmesg | grep -iE "error|fail|warn" | tail -100 >> "$tmpfile" 2>&1
    fi

    textbox "Recent Errors" "$tmpfile"
    rm -f "$tmpfile"
}
