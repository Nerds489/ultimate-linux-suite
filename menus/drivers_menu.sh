#!/usr/bin/env bash
#
# drivers_menu.sh - Driver Manager Menu for Ultimate Linux Suite
#
# Provides driver detection, installation, and management
#

# Prevent multiple sourcing
[[ -n "${_DRIVERS_MENU_SH_LOADED:-}" ]] && return 0
readonly _DRIVERS_MENU_SH_LOADED=1

# ============================================================================
# MAIN DRIVERS MENU
# ============================================================================

run_drivers_menu() {
    local choice

    # Initialize drivers module
    if declare -f module_drivers_init &>/dev/null; then
        module_drivers_init
    fi

    while true; do
        choice=$(menu_select "Driver Manager" \
            "Hardware driver detection and installation:" \
            "detect"      "Detect Hardware & Drivers" \
            "auto"        "Auto-Install Recommended" \
            "realtek_eth" "Realtek r8152 (USB Ethernet)" \
            "realtek_wifi" "Realtek r8821cu (USB WiFi)" \
            "broadcom"    "Broadcom WiFi Drivers" \
            "gpu"         "GPU Driver Guidance" \
            "dkms"        "DKMS Module Management" \
            "vault"       "Driver Vault Status" \
            "back"        "Back to Main Menu")

        case "$choice" in
            detect)
                run_hardware_detection
                ;;
            auto)
                run_auto_install_drivers
                ;;
            realtek_eth)
                run_realtek_r8152_menu
                ;;
            realtek_wifi)
                run_realtek_r8821cu_menu
                ;;
            broadcom)
                run_broadcom_wifi_menu
                ;;
            gpu)
                run_gpu_guidance
                ;;
            dkms)
                run_dkms_menu
                ;;
            vault)
                show_driver_vault_status
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# ============================================================================
# HARDWARE DETECTION
# ============================================================================

run_hardware_detection() {
    show_wait "Detecting hardware and driver requirements..."

    # Run driver detection
    if declare -f module_detect_drivers &>/dev/null; then
        module_detect_drivers
    fi

    # Also run standard hardware detection if available
    if declare -f detect_hardware &>/dev/null; then
        detect_hardware
    fi

    # Build comprehensive info text
    local info_text=""

    info_text+="════════════════════════════════════════════════════════════════\n"
    info_text+="                    HARDWARE DETECTION RESULTS\n"
    info_text+="════════════════════════════════════════════════════════════════\n\n"

    # CPU Info
    info_text+="┌─ CPU ────────────────────────────────────────────────────────┐\n"
    info_text+="│  Vendor: ${CPU_VENDOR:-Unknown}\n"
    info_text+="│  Model:  ${CPU_MODEL:-Unknown}\n"
    info_text+="│  Cores:  ${CPU_CORES:-?} / Threads: ${CPU_THREADS:-?}\n"
    info_text+="│  Virt:   $(has_virtualization 2>/dev/null && echo 'Supported' || echo 'Not detected')\n"
    info_text+="└──────────────────────────────────────────────────────────────┘\n\n"

    # GPU Info
    info_text+="┌─ GPU ────────────────────────────────────────────────────────┐\n"
    info_text+="│  Vendor: ${GPU_VENDOR:-Unknown}\n"
    info_text+="│  Model:  ${GPU_MODEL:-Unknown}\n"
    info_text+="│  Type:   ${GPU_TYPE:-Unknown}\n"
    info_text+="│  Driver: ${GPU_DRIVER:-Not detected}\n"
    if [[ -n "${DRIVER_STATUS[nvidia]:-}" ]]; then
        info_text+="│  Status: ${DRIVER_STATUS[nvidia]}\n"
    elif [[ -n "${DRIVER_STATUS[amd]:-}" ]]; then
        info_text+="│  Status: ${DRIVER_STATUS[amd]}\n"
    elif [[ -n "${DRIVER_STATUS[intel]:-}" ]]; then
        info_text+="│  Status: ${DRIVER_STATUS[intel]}\n"
    fi
    info_text+="└──────────────────────────────────────────────────────────────┘\n\n"

    # Network Info
    info_text+="┌─ Network ────────────────────────────────────────────────────┐\n"
    info_text+="│  WiFi Interfaces:     ${WIFI_INTERFACES[*]:-None detected}\n"
    info_text+="│  Ethernet Interfaces: ${ETH_INTERFACES[*]:-None detected}\n"
    if [[ -n "${DETECTED_HARDWARE[broadcom_wifi]:-}" ]]; then
        info_text+="│  Broadcom WiFi:       ${DETECTED_HARDWARE[broadcom_wifi]} (${DRIVER_STATUS[broadcom_wifi]:-unknown})\n"
    fi
    if [[ -n "${DETECTED_HARDWARE[realtek_wifi]:-}" ]]; then
        info_text+="│  Realtek WiFi:        ${DETECTED_HARDWARE[realtek_wifi]} (${DRIVER_STATUS[realtek_wifi]:-unknown})\n"
    fi
    info_text+="└──────────────────────────────────────────────────────────────┘\n\n"

    # USB Devices
    info_text+="┌─ USB Devices ────────────────────────────────────────────────┐\n"
    if [[ -n "${DETECTED_HARDWARE[realtek_r8152]:-}" ]]; then
        info_text+="│  Realtek r8152 USB Ethernet: ${DETECTED_HARDWARE[realtek_r8152]}\n"
        info_text+="│    Driver status: ${DRIVER_STATUS[realtek_r8152]:-unknown}\n"
    fi
    if [[ -n "${DETECTED_HARDWARE[realtek_r8821cu]:-}" ]]; then
        info_text+="│  Realtek r8821cu USB WiFi:   ${DETECTED_HARDWARE[realtek_r8821cu]}\n"
        info_text+="│    Driver status: ${DRIVER_STATUS[realtek_r8821cu]:-unknown}\n"
    fi
    if [[ -z "${DETECTED_HARDWARE[realtek_r8152]:-}" ]] && [[ -z "${DETECTED_HARDWARE[realtek_r8821cu]:-}" ]]; then
        info_text+="│  No special USB devices detected\n"
    fi
    info_text+="└──────────────────────────────────────────────────────────────┘\n\n"

    # Recommendations
    info_text+="┌─ Recommendations ────────────────────────────────────────────┐\n"
    local has_rec=false
    for driver in "${!DRIVER_STATUS[@]}"; do
        case "${DRIVER_STATUS[$driver]}" in
            needs_driver)
                info_text+="│  ▶ $driver: Installation recommended\n"
                has_rec=true
                ;;
            recommended)
                info_text+="│  ▶ $driver: Driver available\n"
                has_rec=true
                ;;
            check)
                info_text+="│  ▶ $driver: May need attention\n"
                has_rec=true
                ;;
        esac
    done
    if [[ "$has_rec" == "false" ]]; then
        info_text+="│  ✓ All detected hardware has appropriate drivers\n"
    fi
    info_text+="└──────────────────────────────────────────────────────────────┘\n"

    local tmpfile
    tmpfile=$(make_temp "hwdetect")
    echo -e "$info_text" > "$tmpfile"

    textbox "Hardware Detection" "$tmpfile"
    rm -f "$tmpfile"
}

# ============================================================================
# AUTO-INSTALL DRIVERS
# ============================================================================

run_auto_install_drivers() {
    if ! yes_no_prompt "Auto-Install Drivers" \
        "This will detect your hardware and install recommended drivers.\n\nDrivers to be checked:\n- Realtek r8152 USB Ethernet\n- Realtek r8821cu USB WiFi\n- Broadcom WiFi\n\nContinue?"; then
        return 0
    fi

    log_info "Starting auto driver installation"

    # Progress tracking
    local progress_file
    progress_file=$(make_temp "driver_progress")

    (
        echo "5"
        echo "XXX"
        echo "Detecting hardware..."
        echo "XXX"

        if declare -f module_detect_drivers &>/dev/null; then
            module_detect_drivers
        fi

        echo "20"
        echo "XXX"
        echo "Checking kernel headers..."
        echo "XXX"

        if declare -f has_kernel_headers &>/dev/null; then
            if ! has_kernel_headers; then
                echo "25"
                echo "XXX"
                echo "Installing kernel headers..."
                echo "XXX"
                install_kernel_headers 2>/dev/null
            fi
        fi

        local installed=0
        local total=3
        local current=0

        # Check Realtek r8152
        ((current++))
        local pct=$((30 + (current * 20)))
        echo "$pct"
        echo "XXX"
        echo "Checking Realtek r8152..."
        echo "XXX"

        if [[ "${DRIVER_STATUS[realtek_r8152]:-}" == "needs_driver" ]]; then
            echo "$pct"
            echo "XXX"
            echo "Installing Realtek r8152..."
            echo "XXX"
            if declare -f install_realtek_r8152 &>/dev/null && install_realtek_r8152 2>/dev/null; then
                ((installed++))
            fi
        fi

        # Check Realtek r8821cu
        ((current++))
        pct=$((30 + (current * 20)))
        echo "$pct"
        echo "XXX"
        echo "Checking Realtek r8821cu..."
        echo "XXX"

        if [[ "${DRIVER_STATUS[realtek_r8821cu]:-}" == "needs_driver" ]]; then
            echo "$pct"
            echo "XXX"
            echo "Installing Realtek r8821cu..."
            echo "XXX"
            if declare -f install_realtek_r8821cu &>/dev/null && install_realtek_r8821cu 2>/dev/null; then
                ((installed++))
            fi
        fi

        # Check Broadcom WiFi
        ((current++))
        pct=$((30 + (current * 20)))
        echo "$pct"
        echo "XXX"
        echo "Checking Broadcom WiFi..."
        echo "XXX"

        if [[ "${DRIVER_STATUS[broadcom_wifi]:-}" == "needs_driver" ]]; then
            echo "$pct"
            echo "XXX"
            echo "Installing Broadcom WiFi..."
            echo "XXX"
            if declare -f install_broadcom_wifi &>/dev/null && install_broadcom_wifi 2>/dev/null; then
                ((installed++))
            fi
        fi

        echo "100"
        echo "XXX"
        echo "Complete! Installed $installed driver(s)"
        echo "XXX"

        echo "$installed" > "$progress_file"
    ) | dialog --title "Installing Drivers" --gauge "Preparing..." 8 60 0

    local installed_count=0
    [[ -f "$progress_file" ]] && installed_count=$(cat "$progress_file")
    rm -f "$progress_file"

    message_box "Auto-Install Complete" "Driver auto-installation finished.\n\nDrivers installed: $installed_count\n\nNote: A reboot may be required for some drivers to take effect."
}

# ============================================================================
# REALTEK R8152 USB ETHERNET MENU
# ============================================================================

run_realtek_r8152_menu() {
    # Check detection status
    local status_text="Realtek r8152 USB Ethernet Driver\n\n"

    if [[ -n "${DETECTED_HARDWARE[realtek_r8152]:-}" ]]; then
        status_text+="Device: Detected\n"
    else
        status_text+="Device: Not detected (USB IDs: 0bda:8152, 8153, 8156)\n"
    fi

    if lsmod 2>/dev/null | grep -q "^r8152"; then
        status_text+="Driver: Loaded\n"
    else
        status_text+="Driver: Not loaded\n"
    fi

    local choice
    choice=$(menu_select "Realtek r8152 Driver" \
        "$status_text\nSelect action:" \
        "install"   "Install/Load Driver" \
        "remove"    "Remove/Unload Driver" \
        "status"    "Check Status" \
        "back"      "Back")

    case "$choice" in
        install)
            if yes_no_prompt "Install r8152" "Install Realtek r8152 USB Ethernet driver?"; then
                show_wait "Installing r8152 driver..."
                if declare -f install_realtek_r8152 &>/dev/null && install_realtek_r8152; then
                    message_box "Success" "Realtek r8152 driver installed successfully."
                else
                    message_box "Error" "Failed to install r8152 driver.\n\nThe driver may need to be downloaded from Realtek\nand placed in the driver vault."
                fi
            fi
            ;;
        remove)
            if yes_no_prompt "Remove r8152" "Remove Realtek r8152 driver?"; then
                show_wait "Removing r8152 driver..."
                if declare -f remove_realtek_r8152 &>/dev/null && remove_realtek_r8152; then
                    message_box "Success" "Realtek r8152 driver removed."
                else
                    message_box "Error" "Failed to remove r8152 driver."
                fi
            fi
            ;;
        status)
            local stat="Realtek r8152 Status\n\n"
            stat+="Module loaded: $(lsmod | grep -q r8152 && echo 'Yes' || echo 'No')\n"
            stat+="USB device: $(lsusb 2>/dev/null | grep -iE '0bda:(8152|8153|8156)' || echo 'Not detected')\n"

            if have_cmd dkms; then
                local dkms_stat
                dkms_stat=$(dkms status 2>/dev/null | grep r8152 || echo 'Not in DKMS')
                stat+="DKMS: $dkms_stat\n"
            fi

            message_box "r8152 Status" "$stat"
            ;;
        back|"")
            return 0
            ;;
    esac
}

# ============================================================================
# REALTEK R8821CU USB WIFI MENU
# ============================================================================

run_realtek_r8821cu_menu() {
    # Check detection status
    local status_text="Realtek r8821cu USB WiFi Driver\n\n"

    if [[ -n "${DETECTED_HARDWARE[realtek_r8821cu]:-}" ]]; then
        status_text+="Device: Detected\n"
    else
        status_text+="Device: Not detected (USB IDs: 0bda:c811, c82c, c821, b820, c820)\n"
    fi

    if lsmod 2>/dev/null | grep -qE "^8821cu|^rtl8821cu"; then
        status_text+="Driver: Loaded\n"
    else
        status_text+="Driver: Not loaded\n"
    fi

    local choice
    choice=$(menu_select "Realtek r8821cu Driver" \
        "$status_text\nSelect action:" \
        "install"   "Install/Load Driver" \
        "remove"    "Remove/Unload Driver" \
        "status"    "Check Status" \
        "download"  "Download Info" \
        "back"      "Back")

    case "$choice" in
        install)
            if yes_no_prompt "Install r8821cu" "Install Realtek r8821cu USB WiFi driver?\n\nNote: Driver source must be in the driver vault."; then
                show_wait "Installing r8821cu driver..."
                if declare -f install_realtek_r8821cu &>/dev/null && install_realtek_r8821cu; then
                    message_box "Success" "Realtek r8821cu driver installed successfully."
                else
                    message_box "Error" "Failed to install r8821cu driver.\n\nPlease download the driver source from:\nhttps://github.com/morrownr/8821cu-20210916\n\nAnd place it in:\n$DRIVER_VAULT_DIR/realtek-r8821cu/"
                fi
            fi
            ;;
        remove)
            if yes_no_prompt "Remove r8821cu" "Remove Realtek r8821cu driver?"; then
                show_wait "Removing r8821cu driver..."
                if declare -f remove_realtek_r8821cu &>/dev/null && remove_realtek_r8821cu; then
                    message_box "Success" "Realtek r8821cu driver removed."
                else
                    message_box "Error" "Failed to remove r8821cu driver."
                fi
            fi
            ;;
        status)
            local stat="Realtek r8821cu Status\n\n"
            stat+="Module loaded: $(lsmod | grep -qE '8821cu|rtl8821cu' && echo 'Yes' || echo 'No')\n"
            stat+="USB device: $(lsusb 2>/dev/null | grep -iE '0bda:(c811|c82c|c821|b820|c820)' || echo 'Not detected')\n"

            if have_cmd dkms; then
                local dkms_stat
                dkms_stat=$(dkms status 2>/dev/null | grep -E '8821cu|rtl8821cu' || echo 'Not in DKMS')
                stat+="DKMS: $dkms_stat\n"
            fi

            local vault_dir="$DRIVER_VAULT_DIR/realtek-r8821cu"
            if [[ -f "$vault_dir/Makefile" ]] || [[ -f "$vault_dir/dkms.conf" ]]; then
                stat+="Driver vault: Source available\n"
            else
                stat+="Driver vault: Empty\n"
            fi

            message_box "r8821cu Status" "$stat"
            ;;
        download)
            local info="Realtek r8821cu Driver Download\n\n"
            info+="The r8821cu driver is not included in most Linux kernels.\n"
            info+="You need to download and compile from source.\n\n"
            info+="Recommended repository:\n"
            info+="  https://github.com/morrownr/8821cu-20210916\n\n"
            info+="Installation steps:\n"
            info+="1. Clone or download the repository\n"
            info+="2. Extract to: $DRIVER_VAULT_DIR/realtek-r8821cu/\n"
            info+="3. Run the install option in this menu\n\n"
            info+="Alternative (manual):\n"
            info+="  cd [driver-directory]\n"
            info+="  sudo ./dkms-install.sh"

            message_box "Download Information" "$info"
            ;;
        back|"")
            return 0
            ;;
    esac
}

# ============================================================================
# BROADCOM WIFI MENU
# ============================================================================

run_broadcom_wifi_menu() {
    # Check detection status
    local status_text="Broadcom WiFi Driver\n\n"

    if [[ -n "${DETECTED_HARDWARE[broadcom_wifi]:-}" ]]; then
        status_text+="Device: Detected\n"
    else
        status_text+="Device: Not detected\n"
    fi

    # Check which driver is loaded
    if lsmod 2>/dev/null | grep -q "^wl "; then
        status_text+="Driver: wl (proprietary) loaded\n"
    elif lsmod 2>/dev/null | grep -q "^b43 "; then
        status_text+="Driver: b43 (open-source) loaded\n"
    elif lsmod 2>/dev/null | grep -q "^brcmfmac"; then
        status_text+="Driver: brcmfmac loaded\n"
    else
        status_text+="Driver: Not loaded\n"
    fi

    local choice
    choice=$(menu_select "Broadcom WiFi Driver" \
        "$status_text\nSelect action:" \
        "install"   "Install wl Driver" \
        "remove"    "Remove wl Driver" \
        "status"    "Check Status" \
        "info"      "Driver Information" \
        "back"      "Back")

    case "$choice" in
        install)
            if yes_no_prompt "Install Broadcom" "Install Broadcom wl (proprietary) driver?\n\nThis will:\n- Install broadcom-sta or equivalent\n- Blacklist conflicting modules\n- Load the wl module"; then
                show_wait "Installing Broadcom WiFi driver..."
                if declare -f install_broadcom_wifi &>/dev/null && install_broadcom_wifi; then
                    message_box "Success" "Broadcom WiFi driver installed.\n\nYou may need to reboot for changes to take effect."
                else
                    message_box "Error" "Failed to install Broadcom driver.\n\nCheck the logs for details."
                fi
            fi
            ;;
        remove)
            if yes_no_prompt "Remove Broadcom" "Remove Broadcom wl driver?"; then
                show_wait "Removing Broadcom WiFi driver..."
                if declare -f remove_broadcom_wifi &>/dev/null && remove_broadcom_wifi; then
                    message_box "Success" "Broadcom WiFi driver removed."
                else
                    message_box "Error" "Failed to remove Broadcom driver."
                fi
            fi
            ;;
        status)
            local stat="Broadcom WiFi Status\n\n"

            # PCI device info
            local pci_info
            pci_info=$(lspci 2>/dev/null | grep -i broadcom | grep -iE 'network|wireless' | head -1)
            stat+="PCI Device: ${pci_info:-Not detected}\n\n"

            stat+="Loaded modules:\n"
            stat+="  wl:       $(lsmod | grep -q '^wl ' && echo 'Yes' || echo 'No')\n"
            stat+="  b43:      $(lsmod | grep -q '^b43 ' && echo 'Yes' || echo 'No')\n"
            stat+="  brcmfmac: $(lsmod | grep -q '^brcmfmac' && echo 'Yes' || echo 'No')\n\n"

            # Check for blacklist
            if [[ -f /etc/modprobe.d/broadcom-sta-dkms.conf ]]; then
                stat+="Blacklist config: Present\n"
            else
                stat+="Blacklist config: Not found\n"
            fi

            message_box "Broadcom Status" "$stat"
            ;;
        info)
            local info="Broadcom WiFi Drivers\n\n"
            info+="There are several drivers available for Broadcom WiFi:\n\n"
            info+="1. wl (broadcom-sta)\n"
            info+="   - Proprietary driver from Broadcom\n"
            info+="   - Best compatibility for most chips\n"
            info+="   - Requires DKMS\n\n"
            info+="2. b43\n"
            info+="   - Open-source reverse-engineered\n"
            info+="   - Requires firmware (b43-fwcutter)\n"
            info+="   - Limited chip support\n\n"
            info+="3. brcmfmac\n"
            info+="   - Open-source from Broadcom\n"
            info+="   - For newer chips only\n\n"
            info+="This tool installs the wl driver for best compatibility."

            message_box "Broadcom Information" "$info"
            ;;
        back|"")
            return 0
            ;;
    esac
}

# ============================================================================
# GPU GUIDANCE
# ============================================================================

run_gpu_guidance() {
    local guidance=""

    if declare -f get_gpu_guidance &>/dev/null; then
        guidance=$(get_gpu_guidance)
    else
        # Fallback guidance
        guidance="GPU Driver Guidance\n\n"
        guidance+="GPU: ${GPU_VENDOR:-Unknown} ${GPU_MODEL:-Unknown}\n\n"

        case "${GPU_VENDOR:-}" in
            nvidia|NVIDIA)
                guidance+="NVIDIA GPU detected.\n\n"
                guidance+="Current driver: $(lsmod | grep -q nvidia && echo 'Proprietary' || echo 'nouveau/none')\n\n"
                guidance+="Recommendations:\n"
                guidance+="- For gaming/performance: Install NVIDIA proprietary driver\n"
                guidance+="- For basic use: nouveau works but is limited\n\n"
                guidance+="Installation commands:\n"
                guidance+="  Ubuntu: sudo apt install nvidia-driver-xxx\n"
                guidance+="  Fedora: sudo dnf install akmod-nvidia\n"
                guidance+="  Arch: sudo pacman -S nvidia"
                ;;
            amd|AMD)
                guidance+="AMD GPU detected.\n\n"
                guidance+="Current driver: $(lsmod | grep -q amdgpu && echo 'amdgpu' || echo 'radeon/mesa')\n\n"
                guidance+="Recommendations:\n"
                guidance+="- Open-source amdgpu/mesa is usually best\n"
                guidance+="- Ensure vulkan-radeon is installed for gaming\n\n"
                guidance+="Installation commands:\n"
                guidance+="  Ubuntu: sudo apt install mesa-vulkan-drivers\n"
                guidance+="  Fedora: sudo dnf install mesa-vulkan-drivers\n"
                guidance+="  Arch: sudo pacman -S vulkan-radeon"
                ;;
            intel|Intel)
                guidance+="Intel GPU detected.\n\n"
                guidance+="Current driver: $(lsmod | grep -q i915 && echo 'i915' || echo 'not loaded')\n\n"
                guidance+="Intel GPUs typically work out of the box.\n"
                guidance+="For video acceleration, install intel-media-driver."
                ;;
            *)
                guidance+="Unable to determine GPU vendor.\n"
                guidance+="Check 'lspci | grep VGA' for GPU information."
                ;;
        esac
    fi

    message_box "GPU Driver Guidance" "$guidance"
}

# ============================================================================
# DKMS MANAGEMENT MENU
# ============================================================================

run_dkms_menu() {
    local choice

    while true; do
        # Get DKMS status
        local dkms_status="DKMS Module Management\n\n"

        if have_cmd dkms; then
            dkms_status+="DKMS: Installed\n"
            local mod_count
            mod_count=$(dkms status 2>/dev/null | wc -l)
            dkms_status+="Modules: $mod_count registered\n"
        else
            dkms_status+="DKMS: Not installed\n"
        fi

        choice=$(menu_select "DKMS Management" \
            "$dkms_status\nSelect action:" \
            "install"   "Install DKMS" \
            "list"      "List DKMS Modules" \
            "rebuild"   "Rebuild All Modules" \
            "headers"   "Install Kernel Headers" \
            "back"      "Back")

        case "$choice" in
            install)
                if have_cmd dkms; then
                    message_box "DKMS" "DKMS is already installed."
                else
                    if yes_no_prompt "Install DKMS" "Install DKMS (Dynamic Kernel Module Support)?"; then
                        show_wait "Installing DKMS..."
                        if declare -f install_dkms &>/dev/null && install_dkms; then
                            message_box "Success" "DKMS installed successfully."
                        else
                            message_box "Error" "Failed to install DKMS."
                        fi
                    fi
                fi
                ;;
            list)
                if ! have_cmd dkms; then
                    message_box "DKMS" "DKMS is not installed."
                else
                    local modules
                    modules=$(dkms status 2>/dev/null)
                    if [[ -z "$modules" ]]; then
                        message_box "DKMS Modules" "No DKMS modules registered."
                    else
                        local tmpfile
                        tmpfile=$(make_temp "dkms_list")
                        echo "DKMS Registered Modules:" > "$tmpfile"
                        echo "========================" >> "$tmpfile"
                        echo "" >> "$tmpfile"
                        echo "$modules" >> "$tmpfile"
                        textbox "DKMS Modules" "$tmpfile"
                        rm -f "$tmpfile"
                    fi
                fi
                ;;
            rebuild)
                if ! have_cmd dkms; then
                    message_box "DKMS" "DKMS is not installed."
                else
                    if yes_no_prompt "Rebuild DKMS" "Rebuild all DKMS modules for the current kernel?\n\nKernel: $(uname -r)"; then
                        show_wait "Rebuilding DKMS modules..."
                        if declare -f rebuild_dkms_modules &>/dev/null && rebuild_dkms_modules; then
                            message_box "Success" "DKMS modules rebuilt successfully."
                        else
                            message_box "Warning" "DKMS rebuild completed with warnings.\nCheck the logs for details."
                        fi
                    fi
                fi
                ;;
            headers)
                local kernel
                kernel=$(uname -r)
                local headers_installed="Unknown"
                if declare -f has_kernel_headers &>/dev/null; then
                    has_kernel_headers && headers_installed="Yes" || headers_installed="No"
                fi

                if yes_no_prompt "Kernel Headers" "Install kernel headers for current kernel?\n\nKernel: $kernel\nHeaders installed: $headers_installed"; then
                    show_wait "Installing kernel headers..."
                    if declare -f install_kernel_headers &>/dev/null && install_kernel_headers; then
                        message_box "Success" "Kernel headers installed."
                    else
                        message_box "Error" "Failed to install kernel headers."
                    fi
                fi
                ;;
            back|"")
                return 0
                ;;
        esac
    done
}

# ============================================================================
# DRIVER VAULT
# ============================================================================

show_driver_vault_status() {
    local vault_info=""

    if declare -f check_driver_vault &>/dev/null; then
        vault_info=$(check_driver_vault)
    else
        vault_info="Driver Vault: $DRIVER_VAULT_DIR\n\n"

        for dir in realtek-r8152 realtek-r8821cu broadcom nvidia amd intel; do
            local path="${DRIVER_VAULT_DIR:-/tmp}/$dir"
            if [[ -d "$path" ]]; then
                local files
                files=$(find "$path" -maxdepth 1 -type f 2>/dev/null | wc -l)
                if [[ $files -gt 0 ]]; then
                    vault_info+="  $dir: $files file(s)\n"
                else
                    vault_info+="  $dir: empty\n"
                fi
            else
                vault_info+="  $dir: not created\n"
            fi
        done
    fi

    vault_info+="\n\nThe driver vault stores driver sources for offline installation.\n"
    vault_info+="Place driver source code in the appropriate subdirectory."

    message_box "Driver Vault Status" "$vault_info"
}
