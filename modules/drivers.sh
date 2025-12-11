#!/usr/bin/env bash
#
# drivers.sh - Driver Management Module for Ultimate Linux Suite
#
# Provides hardware detection, driver installation, and driver vault
# management for Realtek NICs, Broadcom WiFi, and GPU drivers.
#

# Prevent multiple sourcing
[[ -n "${_MODULE_DRIVERS_LOADED:-}" ]] && return 0
readonly _MODULE_DRIVERS_LOADED=1

# ============================================================================
# GLOBAL VARIABLES
# ============================================================================

# Driver status tracking
declare -gA DRIVER_STATUS=()

# Driver vault directory
declare -g DRIVER_VAULT_DIR="${SUITE_DIR:-$(dirname "$(dirname "${BASH_SOURCE[0]}")")}/drivers"

# Detected hardware
declare -gA DETECTED_HARDWARE=()

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

module_drivers_init() {
    log_debug "Drivers module initialized"
    log_debug "Driver vault: $DRIVER_VAULT_DIR"

    # Ensure driver directories exist
    mkdir -p "$DRIVER_VAULT_DIR"/{realtek-r8152,realtek-r8821cu,broadcom,nvidia,amd,intel} 2>/dev/null

    return 0
}

# ============================================================================
# HARDWARE DETECTION
# ============================================================================

# Main driver detection function
module_detect_drivers() {
    log_info "Detecting hardware and driver requirements..."

    DRIVER_STATUS=()
    DETECTED_HARDWARE=()

    _detect_gpu_driver_needs
    _detect_network_driver_needs
    _detect_usb_devices

    return 0
}

# Detect GPU driver requirements
_detect_gpu_driver_needs() {
    log_debug "Checking GPU driver requirements"

    case "${GPU_VENDOR:-}" in
        nvidia|NVIDIA)
            DETECTED_HARDWARE[gpu]="NVIDIA"
            if lsmod 2>/dev/null | grep -q "^nvidia"; then
                DRIVER_STATUS[nvidia]="installed"
            elif lsmod 2>/dev/null | grep -q "^nouveau"; then
                DRIVER_STATUS[nvidia]="nouveau_active"
            else
                DRIVER_STATUS[nvidia]="recommended"
            fi
            ;;
        amd|AMD)
            DETECTED_HARDWARE[gpu]="AMD"
            if lsmod 2>/dev/null | grep -q "^amdgpu"; then
                DRIVER_STATUS[amd]="installed"
            elif lsmod 2>/dev/null | grep -q "^radeon"; then
                DRIVER_STATUS[amd]="radeon_active"
            else
                DRIVER_STATUS[amd]="recommended"
            fi
            ;;
        intel|Intel)
            DETECTED_HARDWARE[gpu]="Intel"
            if lsmod 2>/dev/null | grep -q "^i915"; then
                DRIVER_STATUS[intel]="installed"
            else
                DRIVER_STATUS[intel]="recommended"
            fi
            ;;
        *)
            DETECTED_HARDWARE[gpu]="Unknown"
            ;;
    esac
}

# Detect network driver requirements
_detect_network_driver_needs() {
    log_debug "Checking network driver requirements"

    # Detect Broadcom WiFi
    if have_cmd lspci; then
        local wifi_info
        wifi_info=$(lspci 2>/dev/null | grep -i 'network\|wireless')

        if echo "$wifi_info" | grep -qi 'broadcom'; then
            DETECTED_HARDWARE[broadcom_wifi]="detected"

            # Check which Broadcom driver is loaded
            if lsmod 2>/dev/null | grep -q "^wl "; then
                DRIVER_STATUS[broadcom_wifi]="wl_installed"
            elif lsmod 2>/dev/null | grep -q "^b43 "; then
                DRIVER_STATUS[broadcom_wifi]="b43_active"
            elif lsmod 2>/dev/null | grep -q "^brcmfmac"; then
                DRIVER_STATUS[broadcom_wifi]="brcmfmac_active"
            else
                DRIVER_STATUS[broadcom_wifi]="needs_driver"
            fi
        fi

        # Check for Realtek WiFi
        if echo "$wifi_info" | grep -qi 'realtek'; then
            DETECTED_HARDWARE[realtek_wifi]="detected"

            if lsmod 2>/dev/null | grep -qE "^rtl8821cu|^rtl88x2bu|^rtw88"; then
                DRIVER_STATUS[realtek_wifi]="installed"
            else
                DRIVER_STATUS[realtek_wifi]="check"
            fi
        fi
    fi
}

# Detect USB devices (Realtek NICs, etc.)
_detect_usb_devices() {
    log_debug "Checking USB devices"

    if ! have_cmd lsusb; then
        return 0
    fi

    local usb_list
    usb_list=$(lsusb 2>/dev/null)

    # Realtek RTL8152/RTL8153 USB Ethernet
    if echo "$usb_list" | grep -qiE "0bda:(8152|8153|8156)"; then
        DETECTED_HARDWARE[realtek_r8152]="detected"

        if lsmod 2>/dev/null | grep -q "^r8152"; then
            DRIVER_STATUS[realtek_r8152]="installed"
        else
            DRIVER_STATUS[realtek_r8152]="needs_driver"
        fi
    fi

    # Realtek RTL8821CU USB WiFi
    if echo "$usb_list" | grep -qiE "0bda:(c811|c82c|c821|b820|c820)"; then
        DETECTED_HARDWARE[realtek_r8821cu]="detected"

        if lsmod 2>/dev/null | grep -qE "^8821cu|^rtl8821cu"; then
            DRIVER_STATUS[realtek_r8821cu]="installed"
        else
            DRIVER_STATUS[realtek_r8821cu]="needs_driver"
        fi
    fi
}

# ============================================================================
# KERNEL HEADERS
# ============================================================================

# Install kernel headers for current kernel
install_kernel_headers() {
    local kernel_version
    kernel_version=$(uname -r)

    log_info "Installing kernel headers for $kernel_version"

    case "$PKG_MANAGER" in
        apt)
            run_as_root apt install -y "linux-headers-$kernel_version"
            ;;
        dnf)
            run_as_root dnf install -y "kernel-devel-$kernel_version" "kernel-headers-$kernel_version"
            ;;
        pacman)
            run_as_root pacman -S --noconfirm --needed linux-headers
            ;;
        zypper)
            run_as_root zypper install -y "kernel-devel-$kernel_version"
            ;;
        *)
            log_warn "Kernel headers installation not supported for $PKG_MANAGER"
            return 1
            ;;
    esac
}

# Check if kernel headers are installed
has_kernel_headers() {
    local kernel_version
    kernel_version=$(uname -r)
    local headers_dir="/lib/modules/$kernel_version/build"

    [[ -d "$headers_dir" ]]
}

# ============================================================================
# DKMS SUPPORT
# ============================================================================

# Install DKMS
install_dkms() {
    if have_cmd dkms; then
        log_debug "DKMS already installed"
        return 0
    fi

    log_info "Installing DKMS"

    case "$PKG_MANAGER" in
        apt)
            run_as_root apt install -y dkms
            ;;
        dnf)
            run_as_root dnf install -y dkms
            ;;
        pacman)
            run_as_root pacman -S --noconfirm --needed dkms
            ;;
        zypper)
            run_as_root zypper install -y dkms
            ;;
    esac
}

# List DKMS modules
list_dkms_modules() {
    if ! have_cmd dkms; then
        echo "DKMS not installed"
        return 1
    fi

    dkms status 2>/dev/null
}

# Rebuild all DKMS modules
rebuild_dkms_modules() {
    if ! have_cmd dkms; then
        log_error "DKMS not installed"
        return 1
    fi

    local kernel_version
    kernel_version=$(uname -r)

    log_info "Rebuilding DKMS modules for kernel $kernel_version"

    # Get list of installed DKMS modules
    local modules
    modules=$(dkms status 2>/dev/null | grep -oP '^[^,]+' | sort -u)

    if [[ -z "$modules" ]]; then
        log_info "No DKMS modules found"
        return 0
    fi

    for mod in $modules; do
        local name version
        name=$(echo "$mod" | cut -d'/' -f1)
        version=$(echo "$mod" | cut -d'/' -f2 | cut -d',' -f1)

        log_info "Rebuilding: $name/$version"
        run_as_root dkms remove "$name/$version" --all 2>/dev/null || true
        run_as_root dkms install "$name/$version" -k "$kernel_version" 2>/dev/null || \
            log_warn "Failed to rebuild $name"
    done

    log_info "DKMS rebuild complete"
}

# ============================================================================
# REALTEK R8152 DRIVER (USB Ethernet)
# ============================================================================

# Install Realtek r8152 driver
install_realtek_r8152() {
    log_info "Installing Realtek r8152 USB Ethernet driver"

    # Check if already loaded
    if lsmod 2>/dev/null | grep -q "^r8152"; then
        log_info "r8152 driver already loaded"
        return 0
    fi

    # The r8152 driver is usually included in the kernel
    # But we may need to install/update it via DKMS for newer devices

    # Ensure kernel headers and DKMS
    if ! has_kernel_headers; then
        install_kernel_headers
    fi

    install_dkms

    # Check driver vault for source
    local vault_dir="$DRIVER_VAULT_DIR/realtek-r8152"

    if [[ -f "$vault_dir/Makefile" ]]; then
        log_info "Building r8152 from driver vault"
        _build_r8152_from_vault "$vault_dir"
    else
        # Try to load built-in module
        log_info "Loading built-in r8152 module"
        run_as_root modprobe r8152 2>/dev/null || {
            log_warn "r8152 module not available in kernel"
            log_info "You may need to download the driver from Realtek"
            return 1
        }
    fi

    # Verify
    if lsmod 2>/dev/null | grep -q "^r8152"; then
        log_info "r8152 driver loaded successfully"
        DRIVER_STATUS[realtek_r8152]="installed"
        return 0
    else
        log_error "Failed to load r8152 driver"
        return 1
    fi
}

# Build r8152 from vault source
_build_r8152_from_vault() {
    local source_dir="$1"

    cd "$source_dir" || return 1

    log_debug "Building r8152 driver..."
    make clean 2>/dev/null || true
    make

    if [[ -f "r8152.ko" ]]; then
        run_as_root make install
        run_as_root depmod -a
        run_as_root modprobe r8152
    fi

    cd - >/dev/null || return 1
}

# Remove Realtek r8152 driver
remove_realtek_r8152() {
    log_info "Removing Realtek r8152 driver"

    run_as_root rmmod r8152 2>/dev/null || true

    # If installed via DKMS
    if have_cmd dkms; then
        local version
        version=$(dkms status 2>/dev/null | grep r8152 | head -1 | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [[ -n "$version" ]]; then
            run_as_root dkms remove "r8152/$version" --all 2>/dev/null || true
        fi
    fi

    DRIVER_STATUS[realtek_r8152]="removed"
    log_info "r8152 driver removed"
}

# ============================================================================
# REALTEK R8821CU DRIVER (USB WiFi)
# ============================================================================

# Install Realtek r8821cu WiFi driver
install_realtek_r8821cu() {
    log_info "Installing Realtek r8821cu USB WiFi driver"

    # Check if already loaded
    if lsmod 2>/dev/null | grep -qE "^8821cu|^rtl8821cu"; then
        log_info "r8821cu driver already loaded"
        return 0
    fi

    # Ensure kernel headers and DKMS
    if ! has_kernel_headers; then
        install_kernel_headers
    fi

    install_dkms

    # Check driver vault for source
    local vault_dir="$DRIVER_VAULT_DIR/realtek-r8821cu"

    if [[ -f "$vault_dir/Makefile" ]] || [[ -f "$vault_dir/dkms.conf" ]]; then
        log_info "Building r8821cu from driver vault"
        _build_r8821cu_from_vault "$vault_dir"
    else
        log_warn "r8821cu source not found in driver vault"
        log_info "Download from: https://github.com/morrownr/8821cu-20210916"
        log_info "Place in: $vault_dir"
        return 1
    fi

    # Verify
    if lsmod 2>/dev/null | grep -qE "^8821cu|^rtl8821cu"; then
        log_info "r8821cu driver loaded successfully"
        DRIVER_STATUS[realtek_r8821cu]="installed"
        return 0
    else
        log_error "Failed to load r8821cu driver"
        return 1
    fi
}

# Build r8821cu from vault source
_build_r8821cu_from_vault() {
    local source_dir="$1"
    local kernel_version
    kernel_version=$(uname -r)

    cd "$source_dir" || return 1

    # Check for DKMS install script
    if [[ -f "dkms-install.sh" ]]; then
        log_debug "Using DKMS install script"
        run_as_root ./dkms-install.sh
    elif [[ -f "dkms.conf" ]]; then
        # Manual DKMS installation
        local version
        version=$(grep -oP 'PACKAGE_VERSION="\K[^"]+' dkms.conf 2>/dev/null || echo "1.0.0")
        local name
        name=$(grep -oP 'PACKAGE_NAME="\K[^"]+' dkms.conf 2>/dev/null || echo "8821cu")

        run_as_root cp -r "$source_dir" "/usr/src/${name}-${version}"
        run_as_root dkms add "${name}/${version}"
        run_as_root dkms build "${name}/${version}" -k "$kernel_version"
        run_as_root dkms install "${name}/${version}" -k "$kernel_version"
    else
        # Direct make
        log_debug "Building directly with make"
        make clean 2>/dev/null || true
        make

        if [[ -f "8821cu.ko" ]]; then
            run_as_root make install
            run_as_root depmod -a
        fi
    fi

    cd - >/dev/null || return 1

    # Load module
    run_as_root modprobe 8821cu 2>/dev/null || \
    run_as_root modprobe rtl8821cu 2>/dev/null || true
}

# Remove Realtek r8821cu driver
remove_realtek_r8821cu() {
    log_info "Removing Realtek r8821cu driver"

    run_as_root rmmod 8821cu 2>/dev/null || true
    run_as_root rmmod rtl8821cu 2>/dev/null || true

    # If installed via DKMS
    if have_cmd dkms; then
        local version
        version=$(dkms status 2>/dev/null | grep -E "8821cu|rtl8821cu" | head -1 | grep -oP '[0-9]+\.[0-9]+' | head -1)
        if [[ -n "$version" ]]; then
            run_as_root dkms remove "8821cu/$version" --all 2>/dev/null || true
        fi
    fi

    DRIVER_STATUS[realtek_r8821cu]="removed"
    log_info "r8821cu driver removed"
}

# ============================================================================
# BROADCOM WIFI DRIVER
# ============================================================================

# Install Broadcom WiFi driver
install_broadcom_wifi() {
    log_info "Installing Broadcom WiFi driver"

    # Detect which Broadcom chipset
    local pci_id
    pci_id=$(lspci -nn 2>/dev/null | grep -i broadcom | grep -i wireless | grep -oP '\[\w+:\w+\]' | tr -d '[]')

    case "$PKG_MANAGER" in
        apt)
            _install_broadcom_debian
            ;;
        dnf)
            _install_broadcom_fedora
            ;;
        pacman)
            _install_broadcom_arch
            ;;
        zypper)
            _install_broadcom_opensuse
            ;;
        *)
            log_warn "Broadcom driver installation not supported for $PKG_MANAGER"
            return 1
            ;;
    esac
}

# Install Broadcom on Debian/Ubuntu
_install_broadcom_debian() {
    log_debug "Installing Broadcom drivers on Debian family"

    # Enable non-free repositories
    if declare -f backend_enable_nonfree &>/dev/null; then
        backend_enable_nonfree
    fi

    # Install broadcom-sta-dkms (wl driver)
    log_info "Installing broadcom-sta-dkms"

    if ! has_kernel_headers; then
        install_kernel_headers
    fi

    run_as_root apt install -y broadcom-sta-dkms

    # Blacklist conflicting modules
    run_as_root tee /etc/modprobe.d/broadcom-sta-dkms.conf > /dev/null << 'EOF'
# Broadcom STA driver blacklist
blacklist b43
blacklist b43legacy
blacklist ssb
blacklist bcm43xx
blacklist brcmsmac
blacklist brcmfmac
EOF

    # Load wl module
    run_as_root modprobe -r b43 ssb wl 2>/dev/null || true
    run_as_root modprobe wl

    DRIVER_STATUS[broadcom_wifi]="wl_installed"
}

# Install Broadcom on Fedora
_install_broadcom_fedora() {
    log_debug "Installing Broadcom drivers on Fedora"

    # Enable RPM Fusion
    if declare -f backend_enable_rpmfusion &>/dev/null; then
        backend_enable_rpmfusion
    fi

    run_as_root dnf install -y broadcom-wl akmod-wl

    # Wait for akmods to build
    log_info "Waiting for kernel module to build..."
    run_as_root akmods --force 2>/dev/null || true

    run_as_root modprobe wl 2>/dev/null || true

    DRIVER_STATUS[broadcom_wifi]="wl_installed"
}

# Install Broadcom on Arch
_install_broadcom_arch() {
    log_debug "Installing Broadcom drivers on Arch"

    if declare -f backend_install_aur &>/dev/null; then
        backend_install_aur broadcom-wl-dkms
    else
        log_warn "AUR helper not available. Install broadcom-wl-dkms manually."
        return 1
    fi

    run_as_root modprobe wl 2>/dev/null || true

    DRIVER_STATUS[broadcom_wifi]="wl_installed"
}

# Install Broadcom on openSUSE
_install_broadcom_opensuse() {
    log_debug "Installing Broadcom drivers on openSUSE"

    run_as_root zypper install -y broadcom-wl broadcom-wl-kmp-default

    run_as_root modprobe wl 2>/dev/null || true

    DRIVER_STATUS[broadcom_wifi]="wl_installed"
}

# Remove Broadcom WiFi driver
remove_broadcom_wifi() {
    log_info "Removing Broadcom WiFi driver"

    run_as_root rmmod wl 2>/dev/null || true

    case "$PKG_MANAGER" in
        apt)
            run_as_root apt remove -y broadcom-sta-dkms
            ;;
        dnf)
            run_as_root dnf remove -y broadcom-wl akmod-wl
            ;;
        pacman)
            run_as_root pacman -R --noconfirm broadcom-wl-dkms 2>/dev/null || true
            ;;
        zypper)
            run_as_root zypper remove -y broadcom-wl
            ;;
    esac

    # Remove blacklist
    run_as_root rm -f /etc/modprobe.d/broadcom-sta-dkms.conf 2>/dev/null

    DRIVER_STATUS[broadcom_wifi]="removed"
}

# ============================================================================
# GPU DRIVERS (Safe Guidance)
# ============================================================================

# Get GPU driver guidance (does not auto-install)
get_gpu_guidance() {
    local gpu="${GPU_VENDOR:-Unknown}"
    local guidance=""

    case "$gpu" in
        nvidia|NVIDIA)
            guidance="NVIDIA GPU Detected: ${GPU_MODEL:-Unknown}\n\n"
            guidance+="Current driver: $(lsmod | grep -q nvidia && echo 'NVIDIA proprietary' || echo 'nouveau/none')\n\n"
            guidance+="Options:\n"
            guidance+="1. Keep nouveau (open-source, limited features)\n"
            guidance+="2. Install NVIDIA proprietary driver (better performance)\n\n"
            guidance+="For Debian/Ubuntu: sudo apt install nvidia-driver\n"
            guidance+="For Fedora: Enable RPM Fusion, then: sudo dnf install akmod-nvidia\n"
            guidance+="For Arch: sudo pacman -S nvidia nvidia-utils\n\n"
            guidance+="Warning: GPU driver changes may affect your display. Have a recovery plan ready."
            ;;
        amd|AMD)
            guidance="AMD GPU Detected: ${GPU_MODEL:-Unknown}\n\n"
            guidance+="Current driver: $(lsmod | grep -q amdgpu && echo 'amdgpu' || echo 'radeon/none')\n\n"
            guidance+="AMD GPUs typically work well with open-source drivers (amdgpu/mesa).\n"
            guidance+="For gaming, ensure mesa and vulkan-radeon are installed.\n\n"
            guidance+="For Debian/Ubuntu: sudo apt install mesa-vulkan-drivers\n"
            guidance+="For Fedora: sudo dnf install mesa-vulkan-drivers\n"
            guidance+="For Arch: sudo pacman -S mesa vulkan-radeon"
            ;;
        intel|Intel)
            guidance="Intel GPU Detected: ${GPU_MODEL:-Unknown}\n\n"
            guidance+="Intel GPUs use the i915 driver (typically built into kernel).\n"
            guidance+="Current status: $(lsmod | grep -q i915 && echo 'i915 loaded' || echo 'not loaded')\n\n"
            guidance+="For video acceleration:\n"
            guidance+="Debian/Ubuntu: sudo apt install intel-media-va-driver\n"
            guidance+="Fedora: sudo dnf install intel-media-driver\n"
            guidance+="Arch: sudo pacman -S intel-media-driver"
            ;;
        *)
            guidance="GPU: ${GPU_MODEL:-Unknown}\n\n"
            guidance+="Unable to provide specific guidance for this GPU.\n"
            guidance+="Please check your distribution's documentation."
            ;;
    esac

    echo -e "$guidance"
}

# ============================================================================
# DRIVER VAULT MANAGEMENT
# ============================================================================

# Check driver vault status
check_driver_vault() {
    local status=""

    status+="Driver Vault: $DRIVER_VAULT_DIR\n\n"

    for dir in realtek-r8152 realtek-r8821cu broadcom nvidia amd intel; do
        local path="$DRIVER_VAULT_DIR/$dir"
        if [[ -d "$path" ]]; then
            local files
            files=$(find "$path" -maxdepth 1 -type f 2>/dev/null | wc -l)
            if [[ $files -gt 0 ]]; then
                status+="  $dir: $files file(s)\n"
            else
                status+="  $dir: empty\n"
            fi
        else
            status+="  $dir: not created\n"
        fi
    done

    echo -e "$status"
}

# ============================================================================
# SUMMARY AND STATUS
# ============================================================================

# Get driver status summary
get_driver_summary() {
    local summary=""

    summary+="=== Detected Hardware ===\n"
    for hw in "${!DETECTED_HARDWARE[@]}"; do
        summary+="  $hw: ${DETECTED_HARDWARE[$hw]}\n"
    done

    summary+="\n=== Driver Status ===\n"
    for driver in "${!DRIVER_STATUS[@]}"; do
        summary+="  $driver: ${DRIVER_STATUS[$driver]}\n"
    done

    echo -e "$summary"
}

# Get recommended actions
get_driver_recommendations() {
    local recommendations=""

    for driver in "${!DRIVER_STATUS[@]}"; do
        case "${DRIVER_STATUS[$driver]}" in
            needs_driver|recommended)
                recommendations+="- $driver: Installation recommended\n"
                ;;
            check)
                recommendations+="- $driver: May need attention\n"
                ;;
        esac
    done

    if [[ -z "$recommendations" ]]; then
        recommendations="All detected hardware has appropriate drivers.\n"
    fi

    echo -e "$recommendations"
}

# Check if driver is loaded
is_driver_loaded() {
    local driver="$1"
    lsmod 2>/dev/null | grep -q "^$driver"
}

# ============================================================================
# AUTO-DETECT AND INSTALL
# ============================================================================

# Auto-detect and install recommended drivers
auto_install_drivers() {
    log_info "Auto-detecting and installing drivers"

    module_detect_drivers

    local installed=0

    # Realtek r8152
    if [[ "${DRIVER_STATUS[realtek_r8152]:-}" == "needs_driver" ]]; then
        log_info "Installing Realtek r8152 driver..."
        if install_realtek_r8152; then
            ((installed++))
        fi
    fi

    # Realtek r8821cu
    if [[ "${DRIVER_STATUS[realtek_r8821cu]:-}" == "needs_driver" ]]; then
        log_info "Installing Realtek r8821cu driver..."
        if install_realtek_r8821cu; then
            ((installed++))
        fi
    fi

    # Broadcom WiFi
    if [[ "${DRIVER_STATUS[broadcom_wifi]:-}" == "needs_driver" ]]; then
        log_info "Installing Broadcom WiFi driver..."
        if install_broadcom_wifi; then
            ((installed++))
        fi
    fi

    log_info "Auto-install complete. Installed $installed driver(s)."
    return 0
}
