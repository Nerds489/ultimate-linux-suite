#!/usr/bin/env bash
#
# opensuse.sh - openSUSE Backend for Ultimate Linux Suite
#
# Provides openSUSE Leap and Tumbleweed specific functionality
#

# Prevent multiple sourcing
[[ -n "${_BACKEND_OPENSUSE_LOADED:-}" ]] && return 0
readonly _BACKEND_OPENSUSE_LOADED=1

# Backend identification
readonly BACKEND_NAME="opensuse"
readonly BACKEND_DISPLAY_NAME="openSUSE"
readonly BACKEND_FAMILY="suse"

# Initialize openSUSE backend
backend_init() {
    log_info "Initializing openSUSE backend"

    if ! have_cmd zypper; then
        log_error "zypper not found - this doesn't appear to be openSUSE"
        return 1
    fi

    log_debug "openSUSE backend initialized"
    return 0
}

# Install packages
backend_install_packages() {
    local packages=("$@")

    log_info "Installing packages: ${packages[*]}"

    run_as_root zypper install -y "${packages[@]}"
}

# Post-setup tasks
backend_post_setup() {
    log_info "Running openSUSE post-setup tasks"

    run_as_root zypper clean

    log_debug "openSUSE post-setup complete"
    return 0
}

# Get version info
backend_get_version_info() {
    local version="${OS_PRETTY_NAME:-openSUSE $OS_VERSION_ID}"
    echo "$version"
}

# Check if Tumbleweed (rolling)
backend_is_tumbleweed() {
    [[ "${OS_ID,,}" == "opensuse-tumbleweed" ]] || \
    [[ "${OS_VERSION_ID,,}" == "tumbleweed" ]] || \
    [[ "${OS_NAME,,}" == *"tumbleweed"* ]]
}

# Check if Leap (stable)
backend_is_leap() {
    [[ "${OS_ID,,}" == "opensuse-leap" ]] || \
    [[ "${OS_NAME,,}" == *"leap"* ]]
}

# Add Packman repository
backend_add_packman() {
    log_info "Adding Packman repository"

    local version
    if backend_is_tumbleweed; then
        version="Tumbleweed"
    else
        version="$OS_VERSION_ID"
    fi

    run_as_root zypper addrepo -cfp 90 \
        "https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_${version}/" \
        packman

    run_as_root zypper refresh
    return 0
}

# Check for Packman repository
backend_has_packman() {
    zypper repos 2>/dev/null | grep -qi packman
}

# Install pattern (group)
backend_install_pattern() {
    local pattern="$1"

    log_info "Installing pattern: $pattern"

    run_as_root zypper install -y -t pattern "$pattern"
}

# System update
backend_system_update() {
    log_info "Updating openSUSE system"

    run_as_root zypper refresh

    if backend_is_tumbleweed; then
        # Tumbleweed uses dup for updates
        run_as_root zypper dup -y
    else
        # Leap uses up for updates
        run_as_root zypper up -y
    fi

    return 0
}

# Install Flatpak packages
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

# Optimization hooks
backend_optimize_kernel() {
    log_info "Applying openSUSE kernel optimizations"
    return 0
}

backend_optimize_services() {
    log_info "Optimizing openSUSE services"
    return 0
}

# Print backend info
backend_print_info() {
    local edition=""
    if backend_is_tumbleweed; then
        edition="Tumbleweed (rolling)"
    elif backend_is_leap; then
        edition="Leap (stable)"
    fi

    echo "Backend: $BACKEND_DISPLAY_NAME"
    echo "  Version: $(backend_get_version_info)"
    echo "  Edition: ${edition:-unknown}"
    echo "  Packman: $(backend_has_packman && echo 'enabled' || echo 'disabled')"
    echo "  Flatpak: $(have_cmd flatpak && echo 'available' || echo 'not found')"
}
