#!/usr/bin/env bash
#
# os_detect.sh - Operating System Detection for Ultimate Linux Suite
#
# Detects Linux distribution, version, family, and appropriate package manager
#

# Prevent multiple sourcing
[[ -n "${_OS_DETECT_SH_LOADED:-}" ]] && return 0
readonly _OS_DETECT_SH_LOADED=1

# OS Detection Results (populated by detect_os)
declare -g OS_ID=""
declare -g OS_ID_LIKE=""
declare -g OS_NAME=""
declare -g OS_VERSION=""
declare -g OS_VERSION_ID=""
declare -g OS_FAMILY=""
declare -g OS_CODENAME=""
declare -g OS_PRETTY_NAME=""
declare -g PKG_MANAGER=""
declare -g PKG_INSTALL_CMD=""
declare -g PKG_UPDATE_CMD=""
declare -g PKG_SEARCH_CMD=""
declare -g PKG_REMOVE_CMD=""

# OS Family constants
declare -gr FAMILY_DEBIAN="debian"
declare -gr FAMILY_FEDORA="fedora"
declare -gr FAMILY_ARCH="arch"
declare -gr FAMILY_SUSE="suse"
declare -gr FAMILY_UNKNOWN="unknown"

# Parse /etc/os-release safely (avoiding VERSION variable conflict)
_parse_os_release() {
    local file="/etc/os-release"
    [[ -r "$file" ]] || return 1

    # Parse specific fields without sourcing the file (avoids VERSION conflicts)
    OS_ID=$(grep -oP '^ID=\K.*' "$file" 2>/dev/null | tr -d '"' | head -1)
    OS_ID_LIKE=$(grep -oP '^ID_LIKE=\K.*' "$file" 2>/dev/null | tr -d '"' | head -1)
    OS_NAME=$(grep -oP '^NAME=\K.*' "$file" 2>/dev/null | tr -d '"' | head -1)
    OS_VERSION=$(grep -oP '^VERSION=\K.*' "$file" 2>/dev/null | tr -d '"' | head -1)
    OS_VERSION_ID=$(grep -oP '^VERSION_ID=\K.*' "$file" 2>/dev/null | tr -d '"' | head -1)
    OS_CODENAME=$(grep -oP '^VERSION_CODENAME=\K.*' "$file" 2>/dev/null | tr -d '"' | head -1)
    OS_PRETTY_NAME=$(grep -oP '^PRETTY_NAME=\K.*' "$file" 2>/dev/null | tr -d '"' | head -1)

    [[ -n "$OS_ID" ]]
}

# Fallback detection methods
_fallback_detection() {
    # Try lsb_release
    if have_cmd lsb_release; then
        OS_ID=$(lsb_release -si 2>/dev/null | tr '[:upper:]' '[:lower:]')
        OS_VERSION_ID=$(lsb_release -sr 2>/dev/null)
        OS_CODENAME=$(lsb_release -sc 2>/dev/null)
        [[ -n "$OS_ID" ]] && return 0
    fi

    # Check for specific release files
    if [[ -f /etc/debian_version ]]; then
        OS_ID="debian"
        OS_VERSION_ID=$(cat /etc/debian_version)
        return 0
    fi

    if [[ -f /etc/redhat-release ]]; then
        OS_ID="rhel"
        OS_VERSION_ID=$(grep -oP '\d+(\.\d+)?' /etc/redhat-release | head -1)
        return 0
    fi

    if [[ -f /etc/arch-release ]]; then
        OS_ID="arch"
        OS_VERSION_ID="rolling"
        return 0
    fi

    if [[ -f /etc/SuSE-release ]]; then
        OS_ID="opensuse"
        return 0
    fi

    return 1
}

# Determine OS family from ID and ID_LIKE
_determine_family() {
    local id="${OS_ID,,}"
    local id_like="${OS_ID_LIKE,,}"

    # Direct matches first
    case "$id" in
        debian|ubuntu|linuxmint|mint|pop|elementary|kali|parrot|zorin|mx|lmde|deepin|peppermint)
            OS_FAMILY="$FAMILY_DEBIAN"
            return 0
            ;;
        fedora|rhel|centos|rocky|alma|almalinux|oracle|scientific|amazon)
            OS_FAMILY="$FAMILY_FEDORA"
            return 0
            ;;
        arch|manjaro|endeavouros|garuda|artix|arcolinux)
            OS_FAMILY="$FAMILY_ARCH"
            return 0
            ;;
        opensuse|opensuse-leap|opensuse-tumbleweed|sles|suse)
            OS_FAMILY="$FAMILY_SUSE"
            return 0
            ;;
    esac

    # Check ID_LIKE for family hints
    if [[ "$id_like" == *"debian"* ]] || [[ "$id_like" == *"ubuntu"* ]]; then
        OS_FAMILY="$FAMILY_DEBIAN"
        return 0
    fi

    if [[ "$id_like" == *"fedora"* ]] || [[ "$id_like" == *"rhel"* ]]; then
        OS_FAMILY="$FAMILY_FEDORA"
        return 0
    fi

    if [[ "$id_like" == *"arch"* ]]; then
        OS_FAMILY="$FAMILY_ARCH"
        return 0
    fi

    if [[ "$id_like" == *"suse"* ]]; then
        OS_FAMILY="$FAMILY_SUSE"
        return 0
    fi

    OS_FAMILY="$FAMILY_UNKNOWN"
    return 1
}

# Set package manager based on family
_set_package_manager() {
    case "$OS_FAMILY" in
        "$FAMILY_DEBIAN")
            PKG_MANAGER="apt"
            PKG_INSTALL_CMD="apt install -y"
            PKG_UPDATE_CMD="apt update"
            PKG_SEARCH_CMD="apt search"
            PKG_REMOVE_CMD="apt remove -y"
            ;;
        "$FAMILY_FEDORA")
            # Check for dnf first (modern Fedora), fall back to yum
            if have_cmd dnf; then
                PKG_MANAGER="dnf"
                PKG_INSTALL_CMD="dnf install -y"
                PKG_UPDATE_CMD="dnf check-update"
                PKG_SEARCH_CMD="dnf search"
                PKG_REMOVE_CMD="dnf remove -y"
            else
                PKG_MANAGER="yum"
                PKG_INSTALL_CMD="yum install -y"
                PKG_UPDATE_CMD="yum check-update"
                PKG_SEARCH_CMD="yum search"
                PKG_REMOVE_CMD="yum remove -y"
            fi
            ;;
        "$FAMILY_ARCH")
            PKG_MANAGER="pacman"
            PKG_INSTALL_CMD="pacman -S --noconfirm"
            PKG_UPDATE_CMD="pacman -Sy"
            PKG_SEARCH_CMD="pacman -Ss"
            PKG_REMOVE_CMD="pacman -R --noconfirm"
            ;;
        "$FAMILY_SUSE")
            PKG_MANAGER="zypper"
            PKG_INSTALL_CMD="zypper install -y"
            PKG_UPDATE_CMD="zypper refresh"
            PKG_SEARCH_CMD="zypper search"
            PKG_REMOVE_CMD="zypper remove -y"
            ;;
        *)
            # Try to detect package manager by availability
            if have_cmd apt; then
                PKG_MANAGER="apt"
                PKG_INSTALL_CMD="apt install -y"
                PKG_UPDATE_CMD="apt update"
                PKG_SEARCH_CMD="apt search"
                PKG_REMOVE_CMD="apt remove -y"
            elif have_cmd dnf; then
                PKG_MANAGER="dnf"
                PKG_INSTALL_CMD="dnf install -y"
                PKG_UPDATE_CMD="dnf check-update"
                PKG_SEARCH_CMD="dnf search"
                PKG_REMOVE_CMD="dnf remove -y"
            elif have_cmd pacman; then
                PKG_MANAGER="pacman"
                PKG_INSTALL_CMD="pacman -S --noconfirm"
                PKG_UPDATE_CMD="pacman -Sy"
                PKG_SEARCH_CMD="pacman -Ss"
                PKG_REMOVE_CMD="pacman -R --noconfirm"
            elif have_cmd zypper; then
                PKG_MANAGER="zypper"
                PKG_INSTALL_CMD="zypper install -y"
                PKG_UPDATE_CMD="zypper refresh"
                PKG_SEARCH_CMD="zypper search"
                PKG_REMOVE_CMD="zypper remove -y"
            else
                PKG_MANAGER="unknown"
                log_warn "Could not detect package manager"
                return 1
            fi
            ;;
    esac

    return 0
}

# Main OS detection function
# Populates all OS_* and PKG_* variables
detect_os() {
    log_debug "Starting OS detection..."

    # Parse os-release first
    if ! _parse_os_release; then
        log_debug "Failed to parse /etc/os-release, trying fallback methods"
        if ! _fallback_detection; then
            log_warn "Could not detect operating system"
            OS_ID="unknown"
            OS_FAMILY="$FAMILY_UNKNOWN"
        fi
    fi

    # Normalize OS_ID to lowercase
    OS_ID="${OS_ID,,}"

    # Determine OS family
    _determine_family

    # Set package manager
    _set_package_manager

    log_debug "OS Detection complete:"
    log_debug "  ID: $OS_ID"
    log_debug "  Family: $OS_FAMILY"
    log_debug "  Version: $OS_VERSION_ID"
    log_debug "  Package Manager: $PKG_MANAGER"

    return 0
}

# Get the backend script name for current OS
get_backend_name() {
    local id="${OS_ID,,}"

    case "$id" in
        debian)           echo "debian" ;;
        ubuntu|pop|elementary|zorin)  echo "ubuntu" ;;
        linuxmint|mint|lmde)   echo "mint" ;;
        fedora)           echo "fedora" ;;
        rhel|centos|rocky|alma|almalinux|oracle)  echo "fedora" ;;
        arch|artix)       echo "arch" ;;
        manjaro|endeavouros|garuda|arcolinux)  echo "arch" ;;
        opensuse*)        echo "opensuse" ;;
        suse|sles)        echo "opensuse" ;;
        kali)             echo "kali" ;;
        parrot)           echo "parrot" ;;
        *)                echo "generic" ;;
    esac
}

# Check if running on a specific distro family
is_debian_family() {
    [[ "$OS_FAMILY" == "$FAMILY_DEBIAN" ]]
}

is_fedora_family() {
    [[ "$OS_FAMILY" == "$FAMILY_FEDORA" ]]
}

is_arch_family() {
    [[ "$OS_FAMILY" == "$FAMILY_ARCH" ]]
}

is_suse_family() {
    [[ "$OS_FAMILY" == "$FAMILY_SUSE" ]]
}

# Check for specific distro
is_distro() {
    local check="${1,,}"
    [[ "${OS_ID,,}" == "$check" ]]
}

# Get OS summary string
get_os_summary() {
    local summary="${OS_PRETTY_NAME:-$OS_NAME}"
    [[ -z "$summary" ]] && summary="$OS_ID $OS_VERSION_ID"
    echo "$summary"
}

# Print detected OS info
print_os_info() {
    echo "Operating System: $(get_os_summary)"
    echo "  Distribution: $OS_ID"
    echo "  Family: $OS_FAMILY"
    echo "  Version: ${OS_VERSION_ID:-unknown}"
    [[ -n "$OS_CODENAME" ]] && echo "  Codename: $OS_CODENAME"
    echo "  Package Manager: $PKG_MANAGER"
}
