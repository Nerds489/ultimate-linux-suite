#!/usr/bin/env bash
#
# generic.sh - Generic Backend for Ultimate Linux Suite
#
# Fallback backend for unknown or unsupported distributions
# Attempts to work with any Linux system
#

# Prevent multiple sourcing
[[ -n "${_BACKEND_GENERIC_LOADED:-}" ]] && return 0
readonly _BACKEND_GENERIC_LOADED=1

# Backend identification
readonly BACKEND_NAME="generic"
readonly BACKEND_DISPLAY_NAME="Generic Linux"
readonly BACKEND_FAMILY="unknown"

# Detected package manager for generic systems
declare -g GENERIC_PKG_MANAGER=""

# Initialize generic backend
backend_init() {
    log_info "Initializing generic backend"
    log_warn "Using generic backend - some features may not work"

    # Try to detect a package manager
    if have_cmd apt; then
        GENERIC_PKG_MANAGER="apt"
    elif have_cmd dnf; then
        GENERIC_PKG_MANAGER="dnf"
    elif have_cmd yum; then
        GENERIC_PKG_MANAGER="yum"
    elif have_cmd pacman; then
        GENERIC_PKG_MANAGER="pacman"
    elif have_cmd zypper; then
        GENERIC_PKG_MANAGER="zypper"
    elif have_cmd apk; then
        GENERIC_PKG_MANAGER="apk"
    elif have_cmd emerge; then
        GENERIC_PKG_MANAGER="portage"
    elif have_cmd xbps-install; then
        GENERIC_PKG_MANAGER="xbps"
    elif have_cmd pkg; then
        GENERIC_PKG_MANAGER="pkg"
    else
        log_warn "No supported package manager found"
        GENERIC_PKG_MANAGER="none"
    fi

    log_debug "Generic backend initialized with: $GENERIC_PKG_MANAGER"
    return 0
}

# Install packages
backend_install_packages() {
    local packages=("$@")

    log_info "Installing packages: ${packages[*]}"

    case "$GENERIC_PKG_MANAGER" in
        apt)
            run_as_root apt update
            run_as_root apt install -y "${packages[@]}"
            ;;
        dnf)
            run_as_root dnf install -y "${packages[@]}"
            ;;
        yum)
            run_as_root yum install -y "${packages[@]}"
            ;;
        pacman)
            run_as_root pacman -S --noconfirm "${packages[@]}"
            ;;
        zypper)
            run_as_root zypper install -y "${packages[@]}"
            ;;
        apk)
            run_as_root apk add "${packages[@]}"
            ;;
        portage)
            run_as_root emerge "${packages[@]}"
            ;;
        xbps)
            run_as_root xbps-install -y "${packages[@]}"
            ;;
        pkg)
            run_as_root pkg install -y "${packages[@]}"
            ;;
        none)
            log_error "No package manager available"
            return 1
            ;;
        *)
            log_error "Unknown package manager: $GENERIC_PKG_MANAGER"
            return 1
            ;;
    esac
}

# Post-setup tasks
backend_post_setup() {
    log_info "Running generic post-setup tasks"

    case "$GENERIC_PKG_MANAGER" in
        apt)
            run_as_root apt autoremove -y
            run_as_root apt clean
            ;;
        dnf)
            run_as_root dnf autoremove -y
            run_as_root dnf clean all
            ;;
        yum)
            run_as_root yum autoremove -y
            run_as_root yum clean all
            ;;
        pacman)
            local orphans
            orphans=$(pacman -Qdtq 2>/dev/null)
            [[ -n "$orphans" ]] && run_as_root pacman -Rns --noconfirm $orphans
            ;;
        zypper)
            run_as_root zypper clean
            ;;
    esac

    log_debug "Generic post-setup complete"
    return 0
}

# Get version info
backend_get_version_info() {
    local version="${OS_PRETTY_NAME:-Unknown Linux $OS_VERSION_ID}"
    echo "$version"
}

# System update
backend_system_update() {
    log_info "Updating system"

    case "$GENERIC_PKG_MANAGER" in
        apt)
            run_as_root apt update
            run_as_root apt upgrade -y
            ;;
        dnf)
            run_as_root dnf upgrade -y
            ;;
        yum)
            run_as_root yum update -y
            ;;
        pacman)
            run_as_root pacman -Syu --noconfirm
            ;;
        zypper)
            run_as_root zypper update -y
            ;;
        apk)
            run_as_root apk update
            run_as_root apk upgrade
            ;;
        portage)
            run_as_root emerge --sync
            run_as_root emerge -uDN @world
            ;;
        xbps)
            run_as_root xbps-install -Su
            ;;
        pkg)
            run_as_root pkg update
            run_as_root pkg upgrade -y
            ;;
        *)
            log_warn "Cannot update: no package manager"
            return 1
            ;;
    esac

    return 0
}

# Install Flatpak packages (universal)
backend_install_flatpak() {
    local packages=("$@")

    if ! have_cmd flatpak; then
        log_warn "Flatpak not available"
        return 1
    fi

    for pkg in "${packages[@]}"; do
        log_info "Installing flatpak: $pkg"
        flatpak install -y flathub "$pkg"
    done
}

# Check for Flatpak
backend_has_flatpak() {
    have_cmd flatpak
}

# Check for Snap
backend_has_snap() {
    have_cmd snap
}

# Optimization hooks (minimal for generic)
backend_optimize_kernel() {
    log_info "Kernel optimization not available for generic backend"
    return 0
}

backend_optimize_services() {
    log_info "Service optimization not available for generic backend"
    return 0
}

# Print backend info
backend_print_info() {
    echo "Backend: $BACKEND_DISPLAY_NAME"
    echo "  OS: $(backend_get_version_info)"
    echo "  Package Manager: ${GENERIC_PKG_MANAGER:-none}"
    echo "  Flatpak: $(backend_has_flatpak && echo 'available' || echo 'not found')"
    echo "  Snap: $(backend_has_snap && echo 'available' || echo 'not found')"
}
