#!/usr/bin/env bash
#
# ubuntu.sh - Ubuntu Backend for Ultimate Linux Suite
#
# Provides Ubuntu-specific functionality (also covers Pop!_OS, Elementary)
#

# Prevent multiple sourcing
[[ -n "${_BACKEND_UBUNTU_LOADED:-}" ]] && return 0
readonly _BACKEND_UBUNTU_LOADED=1

# Backend identification
readonly BACKEND_NAME="ubuntu"
readonly BACKEND_DISPLAY_NAME="Ubuntu"
readonly BACKEND_FAMILY="debian"

# Initialize Ubuntu backend
backend_init() {
    log_info "Initializing Ubuntu backend"

    # Check for Ubuntu-specific tools
    local tools=("apt" "dpkg" "snap" "ubuntu-drivers")
    for tool in "${tools[@]}"; do
        if ! have_cmd "$tool"; then
            log_debug "Ubuntu tool not available: $tool"
        fi
    done

    log_debug "Ubuntu backend initialized"
    return 0
}

# Install packages
backend_install_packages() {
    local packages=("$@")

    log_info "Installing packages: ${packages[*]}"

    run_as_root apt update || log_warn "apt update had issues"
    run_as_root apt install -y "${packages[@]}"
}

# Post-setup tasks
backend_post_setup() {
    log_info "Running Ubuntu post-setup tasks"

    run_as_root apt autoremove -y
    run_as_root apt clean

    log_debug "Ubuntu post-setup complete"
    return 0
}

# Get Ubuntu version info
backend_get_version_info() {
    local version="${OS_PRETTY_NAME:-Ubuntu $OS_VERSION_ID}"
    echo "$version"
}

# Check for universe repository
backend_has_universe() {
    grep -qE 'universe' /etc/apt/sources.list 2>/dev/null || \
    grep -rqE 'universe' /etc/apt/sources.list.d/ 2>/dev/null
}

# Enable universe repository
backend_enable_universe() {
    log_info "Enabling universe repository"

    if backend_has_universe; then
        log_debug "Universe repository already enabled"
        return 0
    fi

    if have_cmd add-apt-repository; then
        run_as_root add-apt-repository universe -y
        run_as_root apt update
    fi

    return 0
}

# Check for multiverse repository
backend_has_multiverse() {
    grep -qE 'multiverse' /etc/apt/sources.list 2>/dev/null || \
    grep -rqE 'multiverse' /etc/apt/sources.list.d/ 2>/dev/null
}

# Enable multiverse repository
backend_enable_multiverse() {
    log_info "Enabling multiverse repository"

    if backend_has_multiverse; then
        log_debug "Multiverse repository already enabled"
        return 0
    fi

    if have_cmd add-apt-repository; then
        run_as_root add-apt-repository multiverse -y
        run_as_root apt update
    fi

    return 0
}

# Install Snap packages
backend_install_snap() {
    local packages=("$@")

    if ! have_cmd snap; then
        log_warn "Snap not available"
        return 1
    fi

    for pkg in "${packages[@]}"; do
        log_info "Installing snap: $pkg"
        run_as_root snap install "$pkg"
    done
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

# Auto-install drivers
backend_autoinstall_drivers() {
    log_info "Auto-installing Ubuntu drivers"

    if have_cmd ubuntu-drivers; then
        run_as_root ubuntu-drivers autoinstall
    else
        log_warn "ubuntu-drivers not available"
        return 1
    fi

    return 0
}

# Optimization hooks
backend_optimize_kernel() {
    log_info "Applying Ubuntu kernel optimizations"
    return 0
}

backend_optimize_services() {
    log_info "Optimizing Ubuntu services"
    return 0
}

# Print backend info
backend_print_info() {
    echo "Backend: $BACKEND_DISPLAY_NAME"
    echo "  Version: $(backend_get_version_info)"
    echo "  Universe: $(backend_has_universe && echo 'enabled' || echo 'disabled')"
    echo "  Multiverse: $(backend_has_multiverse && echo 'enabled' || echo 'disabled')"
    echo "  Snap: $(have_cmd snap && echo 'available' || echo 'not found')"
}
