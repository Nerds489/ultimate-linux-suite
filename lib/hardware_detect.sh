#!/usr/bin/env bash
#
# hardware_detect.sh - Hardware Detection for Ultimate Linux Suite
#
# Detects CPU, GPU, Memory, Storage, Network, and form factor
#

# Prevent multiple sourcing
[[ -n "${_HARDWARE_DETECT_SH_LOADED:-}" ]] && return 0
readonly _HARDWARE_DETECT_SH_LOADED=1

# Hardware Detection Results
declare -g CPU_VENDOR=""
declare -g CPU_MODEL=""
declare -g CPU_CORES=0
declare -g CPU_THREADS=0
declare -g CPU_FLAGS=""
declare -g CPU_HAS_VIRT=0
declare -g CPU_HAS_AES=0
declare -g CPU_HAS_AVX=0

declare -g GPU_VENDOR=""
declare -g GPU_MODEL=""
declare -g GPU_TYPE=""  # integrated, discrete, hybrid
declare -g GPU_DRIVER=""

declare -g TOTAL_RAM_KB=0
declare -g TOTAL_RAM_MB=0
declare -g TOTAL_RAM_GB=0
declare -g SWAP_SIZE_KB=0
declare -g SWAP_SIZE_MB=0

declare -g ROOT_DEVICE=""
declare -g ROOT_FS_TYPE=""
declare -g STORAGE_TYPE=""  # ssd, hdd, nvme, mixed

declare -g FORM_FACTOR=""  # laptop, desktop, server, vm, unknown
declare -g IS_LAPTOP=0
declare -g IS_VM=0

declare -ga NETWORK_INTERFACES=()
declare -ga WIFI_INTERFACES=()
declare -ga ETH_INTERFACES=()

# CPU Detection
detect_cpu() {
    log_debug "Detecting CPU..."

    local cpuinfo="/proc/cpuinfo"
    [[ -r "$cpuinfo" ]] || { log_warn "Cannot read $cpuinfo"; return 1; }

    # Get vendor
    CPU_VENDOR=$(grep -m1 'vendor_id' "$cpuinfo" 2>/dev/null | cut -d: -f2 | tr -d ' ')
    case "$CPU_VENDOR" in
        GenuineIntel) CPU_VENDOR="Intel" ;;
        AuthenticAMD) CPU_VENDOR="AMD" ;;
        ARM*)         CPU_VENDOR="ARM" ;;
        *)
            # ARM devices may not have vendor_id
            if grep -q 'CPU architecture' "$cpuinfo" 2>/dev/null; then
                CPU_VENDOR="ARM"
            fi
            ;;
    esac

    # Get model name
    CPU_MODEL=$(grep -m1 'model name' "$cpuinfo" 2>/dev/null | cut -d: -f2 | sed 's/^[ \t]*//')
    [[ -z "$CPU_MODEL" ]] && CPU_MODEL=$(grep -m1 'Hardware' "$cpuinfo" 2>/dev/null | cut -d: -f2 | sed 's/^[ \t]*//')

    # Count physical cores and threads
    CPU_CORES=$(grep -c '^processor' "$cpuinfo" 2>/dev/null || echo 1)
    local siblings
    siblings=$(grep -m1 'siblings' "$cpuinfo" 2>/dev/null | cut -d: -f2 | tr -d ' ')
    local cores_per_socket
    cores_per_socket=$(grep -m1 'cpu cores' "$cpuinfo" 2>/dev/null | cut -d: -f2 | tr -d ' ')

    if [[ -n "$siblings" ]] && [[ -n "$cores_per_socket" ]]; then
        local sockets
        sockets=$(grep -c 'physical id' "$cpuinfo" 2>/dev/null | sort -u | wc -l)
        [[ $sockets -lt 1 ]] && sockets=1
        CPU_THREADS=$((siblings * sockets))
        CPU_CORES=$((cores_per_socket * sockets))
    else
        CPU_THREADS=$CPU_CORES
    fi

    # Get CPU flags
    CPU_FLAGS=$(grep -m1 '^flags' "$cpuinfo" 2>/dev/null | cut -d: -f2)
    [[ -z "$CPU_FLAGS" ]] && CPU_FLAGS=$(grep -m1 '^Features' "$cpuinfo" 2>/dev/null | cut -d: -f2)

    # Check for specific capabilities
    if [[ "$CPU_FLAGS" == *"vmx"* ]] || [[ "$CPU_FLAGS" == *"svm"* ]]; then
        CPU_HAS_VIRT=1
    fi
    if [[ "$CPU_FLAGS" == *"aes"* ]]; then
        CPU_HAS_AES=1
    fi
    if [[ "$CPU_FLAGS" == *"avx"* ]]; then
        CPU_HAS_AVX=1
    fi

    log_debug "CPU: $CPU_VENDOR $CPU_MODEL ($CPU_CORES cores, $CPU_THREADS threads)"
    return 0
}

# GPU Detection
detect_gpu() {
    log_debug "Detecting GPU..."

    GPU_VENDOR=""
    GPU_MODEL=""
    GPU_TYPE="unknown"
    GPU_DRIVER=""

    local has_nvidia=0
    local has_amd=0
    local has_intel=0

    # Try lspci first
    if have_cmd lspci; then
        local vga_info
        vga_info=$(lspci 2>/dev/null | grep -iE 'vga|3d|display')

        if echo "$vga_info" | grep -qi nvidia; then
            has_nvidia=1
            GPU_MODEL=$(echo "$vga_info" | grep -i nvidia | head -1 | sed 's/.*: //')
        fi
        if echo "$vga_info" | grep -qi 'amd\|ati\|radeon'; then
            has_amd=1
            [[ -z "$GPU_MODEL" ]] && GPU_MODEL=$(echo "$vga_info" | grep -iE 'amd|ati|radeon' | head -1 | sed 's/.*: //')
        fi
        if echo "$vga_info" | grep -qi intel; then
            has_intel=1
            [[ -z "$GPU_MODEL" ]] && GPU_MODEL=$(echo "$vga_info" | grep -i intel | head -1 | sed 's/.*: //')
        fi
    fi

    # Determine vendor and type
    if [[ $has_nvidia -eq 1 ]]; then
        GPU_VENDOR="NVIDIA"
        if [[ $has_intel -eq 1 ]] || [[ $has_amd -eq 1 ]]; then
            GPU_TYPE="hybrid"
        else
            GPU_TYPE="discrete"
        fi
    elif [[ $has_amd -eq 1 ]]; then
        GPU_VENDOR="AMD"
        if [[ $has_intel -eq 1 ]]; then
            GPU_TYPE="hybrid"
        elif echo "$GPU_MODEL" | grep -qi 'integrated\|vega.*graphics'; then
            GPU_TYPE="integrated"
        else
            GPU_TYPE="discrete"
        fi
    elif [[ $has_intel -eq 1 ]]; then
        GPU_VENDOR="Intel"
        GPU_TYPE="integrated"
    fi

    # Check for loaded drivers
    if have_cmd lsmod; then
        if lsmod 2>/dev/null | grep -q nvidia; then
            GPU_DRIVER="nvidia"
        elif lsmod 2>/dev/null | grep -q nouveau; then
            GPU_DRIVER="nouveau"
        elif lsmod 2>/dev/null | grep -q amdgpu; then
            GPU_DRIVER="amdgpu"
        elif lsmod 2>/dev/null | grep -q radeon; then
            GPU_DRIVER="radeon"
        elif lsmod 2>/dev/null | grep -q i915; then
            GPU_DRIVER="i915"
        fi
    fi

    log_debug "GPU: $GPU_VENDOR $GPU_MODEL ($GPU_TYPE, driver: ${GPU_DRIVER:-unknown})"
    return 0
}

# Memory Detection
detect_memory() {
    log_debug "Detecting memory..."

    local meminfo="/proc/meminfo"
    [[ -r "$meminfo" ]] || { log_warn "Cannot read $meminfo"; return 1; }

    # Total RAM
    TOTAL_RAM_KB=$(grep -m1 '^MemTotal:' "$meminfo" 2>/dev/null | awk '{print $2}')
    TOTAL_RAM_KB="${TOTAL_RAM_KB:-0}"
    TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
    TOTAL_RAM_GB=$((TOTAL_RAM_MB / 1024))

    # Swap
    SWAP_SIZE_KB=$(grep -m1 '^SwapTotal:' "$meminfo" 2>/dev/null | awk '{print $2}')
    SWAP_SIZE_KB="${SWAP_SIZE_KB:-0}"
    SWAP_SIZE_MB=$((SWAP_SIZE_KB / 1024))

    log_debug "Memory: ${TOTAL_RAM_GB}GB RAM, ${SWAP_SIZE_MB}MB Swap"
    return 0
}

# Storage Detection
detect_storage() {
    log_debug "Detecting storage..."

    ROOT_DEVICE=""
    ROOT_FS_TYPE=""
    STORAGE_TYPE="unknown"

    # Get root device
    if have_cmd findmnt; then
        ROOT_DEVICE=$(findmnt -n -o SOURCE / 2>/dev/null)
        ROOT_FS_TYPE=$(findmnt -n -o FSTYPE / 2>/dev/null)
    elif have_cmd df; then
        ROOT_DEVICE=$(df / 2>/dev/null | tail -1 | awk '{print $1}')
    fi

    # Resolve any symlinks
    if [[ -L "$ROOT_DEVICE" ]]; then
        ROOT_DEVICE=$(readlink -f "$ROOT_DEVICE" 2>/dev/null || echo "$ROOT_DEVICE")
    fi

    # Determine storage type from root device
    if [[ -n "$ROOT_DEVICE" ]]; then
        local base_device
        base_device=$(echo "$ROOT_DEVICE" | sed 's/[0-9]*$//' | sed 's/p$//')
        base_device=$(basename "$base_device")

        if [[ -r "/sys/block/$base_device/queue/rotational" ]]; then
            local rotational
            rotational=$(cat "/sys/block/$base_device/queue/rotational" 2>/dev/null)
            if [[ "$rotational" == "0" ]]; then
                if [[ "$base_device" == nvme* ]]; then
                    STORAGE_TYPE="nvme"
                else
                    STORAGE_TYPE="ssd"
                fi
            else
                STORAGE_TYPE="hdd"
            fi
        fi
    fi

    log_debug "Storage: $ROOT_DEVICE ($ROOT_FS_TYPE, type: $STORAGE_TYPE)"
    return 0
}

# Network Interface Detection
detect_network() {
    log_debug "Detecting network interfaces..."

    NETWORK_INTERFACES=()
    WIFI_INTERFACES=()
    ETH_INTERFACES=()

    # Get list of interfaces
    local iface
    if [[ -d /sys/class/net ]]; then
        for iface_path in /sys/class/net/*; do
            iface=$(basename "$iface_path")
            [[ "$iface" == "lo" ]] && continue

            NETWORK_INTERFACES+=("$iface")

            # Check if wireless
            if [[ -d "/sys/class/net/$iface/wireless" ]] || \
               [[ -d "/sys/class/net/$iface/phy80211" ]]; then
                WIFI_INTERFACES+=("$iface")
            else
                # Check device type
                local devtype
                devtype=$(cat "/sys/class/net/$iface/type" 2>/dev/null)
                if [[ "$devtype" == "1" ]]; then
                    ETH_INTERFACES+=("$iface")
                fi
            fi
        done
    fi

    # Alternative: use ip command
    if [[ ${#NETWORK_INTERFACES[@]} -eq 0 ]] && have_cmd ip; then
        while IFS= read -r line; do
            iface=$(echo "$line" | awk -F: '{print $2}' | tr -d ' ')
            [[ -n "$iface" ]] && [[ "$iface" != "lo" ]] && NETWORK_INTERFACES+=("$iface")
        done < <(ip link show 2>/dev/null | grep '^[0-9]')
    fi

    log_debug "Network: ${#NETWORK_INTERFACES[@]} interfaces (${#WIFI_INTERFACES[@]} WiFi, ${#ETH_INTERFACES[@]} Ethernet)"
    return 0
}

# Form Factor Detection
detect_form_factor() {
    log_debug "Detecting form factor..."

    FORM_FACTOR="unknown"
    IS_LAPTOP=0
    IS_VM=0

    # Check for VM first
    if [[ -r /sys/class/dmi/id/product_name ]]; then
        local product
        product=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
        case "${product,,}" in
            *virtual*|*vmware*|*virtualbox*|*kvm*|*qemu*|*xen*)
                IS_VM=1
                FORM_FACTOR="vm"
                log_debug "Form factor: Virtual Machine ($product)"
                return 0
                ;;
        esac
    fi

    # Check systemd-detect-virt
    if have_cmd systemd-detect-virt; then
        local virt
        virt=$(systemd-detect-virt 2>/dev/null)
        if [[ "$virt" != "none" ]] && [[ -n "$virt" ]]; then
            IS_VM=1
            FORM_FACTOR="vm"
            log_debug "Form factor: Virtual Machine ($virt)"
            return 0
        fi
    fi

    # Check chassis type
    if [[ -r /sys/class/dmi/id/chassis_type ]]; then
        local chassis
        chassis=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null)
        case "$chassis" in
            8|9|10|11|12|14|18|21)
                # Portable, Laptop, Notebook, Hand Held, Docking Station, Sub Notebook, etc.
                IS_LAPTOP=1
                FORM_FACTOR="laptop"
                ;;
            3|4|5|6|7|13|15|16|17)
                # Desktop, Low Profile Desktop, Pizza Box, Mini Tower, Tower, etc.
                FORM_FACTOR="desktop"
                ;;
            23|24|25|28|29)
                # Rack Mount, Blade, etc.
                FORM_FACTOR="server"
                ;;
        esac
    fi

    # Fallback: check for battery
    if [[ "$FORM_FACTOR" == "unknown" ]]; then
        if [[ -d /sys/class/power_supply ]]; then
            for ps in /sys/class/power_supply/*/type; do
                if [[ -r "$ps" ]] && grep -qi battery "$ps" 2>/dev/null; then
                    IS_LAPTOP=1
                    FORM_FACTOR="laptop"
                    break
                fi
            done
        fi
    fi

    [[ "$FORM_FACTOR" == "unknown" ]] && FORM_FACTOR="desktop"

    log_debug "Form factor: $FORM_FACTOR"
    return 0
}

# Main hardware detection function
detect_hardware() {
    log_section "Hardware Detection"

    detect_cpu
    detect_gpu
    detect_memory
    detect_storage
    detect_network
    detect_form_factor

    log_debug "Hardware detection complete"
    return 0
}

# Getter functions for external use
get_cpu_vendor() { echo "$CPU_VENDOR"; }
get_cpu_model() { echo "$CPU_MODEL"; }
get_cpu_cores() { echo "$CPU_CORES"; }
get_cpu_threads() { echo "$CPU_THREADS"; }

get_total_ram_mb() { echo "$TOTAL_RAM_MB"; }
get_total_ram_gb() { echo "$TOTAL_RAM_GB"; }
get_swap_mb() { echo "$SWAP_SIZE_MB"; }

get_gpu_vendor() { echo "$GPU_VENDOR"; }
get_gpu_model() { echo "$GPU_MODEL"; }
get_gpu_type() { echo "$GPU_TYPE"; }
get_gpu_driver() { echo "$GPU_DRIVER"; }

get_storage_type() { echo "$STORAGE_TYPE"; }
get_root_device() { echo "$ROOT_DEVICE"; }
get_root_fstype() { echo "$ROOT_FS_TYPE"; }

get_form_factor() { echo "$FORM_FACTOR"; }
is_laptop() { [[ $IS_LAPTOP -eq 1 ]]; }
is_vm() { [[ $IS_VM -eq 1 ]]; }

has_virtualization() { [[ $CPU_HAS_VIRT -eq 1 ]]; }
has_aes() { [[ $CPU_HAS_AES -eq 1 ]]; }
has_avx() { [[ $CPU_HAS_AVX -eq 1 ]]; }

get_network_interfaces() { echo "${NETWORK_INTERFACES[*]}"; }
get_wifi_interfaces() { echo "${WIFI_INTERFACES[*]}"; }
get_eth_interfaces() { echo "${ETH_INTERFACES[*]}"; }

# CPU summary string
get_cpu_summary() {
    echo "$CPU_VENDOR $CPU_MODEL ($CPU_CORES cores / $CPU_THREADS threads)"
}

# Network summary string
get_network_summary() {
    local wifi_count=${#WIFI_INTERFACES[@]}
    local eth_count=${#ETH_INTERFACES[@]}
    echo "$wifi_count WiFi, $eth_count Ethernet"
}

# Print full hardware summary
print_hardware_info() {
    echo "Hardware Information:"
    echo "  CPU: $(get_cpu_summary)"
    echo "    Virtualization: $(has_virtualization && echo 'Yes' || echo 'No')"
    echo "    AES-NI: $(has_aes && echo 'Yes' || echo 'No')"
    echo "  GPU: $GPU_VENDOR ${GPU_MODEL:-Unknown} ($GPU_TYPE)"
    [[ -n "$GPU_DRIVER" ]] && echo "    Driver: $GPU_DRIVER"
    echo "  Memory: ${TOTAL_RAM_GB}GB RAM, ${SWAP_SIZE_MB}MB Swap"
    echo "  Storage: $STORAGE_TYPE (root: $ROOT_FS_TYPE on $ROOT_DEVICE)"
    echo "  Network: $(get_network_summary)"
    echo "  Form Factor: $FORM_FACTOR"
}
