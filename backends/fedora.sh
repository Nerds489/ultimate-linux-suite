#!/usr/bin/env bash
#
# fedora.sh - Fedora Backend for Ultimate Linux Suite
#
# Provides Fedora and RHEL-family specific functionality
# Covers: Fedora, RHEL, CentOS, Rocky, AlmaLinux
#

# Prevent multiple sourcing
[[ -n "${_BACKEND_FEDORA_LOADED:-}" ]] && return 0
readonly _BACKEND_FEDORA_LOADED=1

# Backend identification
readonly BACKEND_NAME="fedora"
readonly BACKEND_DISPLAY_NAME="Fedora"
readonly BACKEND_FAMILY="fedora"

# Initialize Fedora backend
backend_init() {
    log_info "Initializing Fedora backend"

    # Determine if using dnf or yum
    if have_cmd dnf; then
        log_debug "Using DNF package manager"
    elif have_cmd yum; then
        log_debug "Using YUM package manager"
    else
        log_warn "Neither dnf nor yum found"
    fi

    log_debug "Fedora backend initialized"
    return 0
}

# Install packages
backend_install_packages() {
    local packages=("$@")

    log_info "Installing packages: ${packages[*]}"

    if have_cmd dnf; then
        run_as_root dnf install -y "${packages[@]}"
    else
        run_as_root yum install -y "${packages[@]}"
    fi
}

# Post-setup tasks
backend_post_setup() {
    log_info "Running Fedora post-setup tasks"

    if have_cmd dnf; then
        run_as_root dnf autoremove -y
        run_as_root dnf clean all
    else
        run_as_root yum autoremove -y
        run_as_root yum clean all
    fi

    log_debug "Fedora post-setup complete"
    return 0
}

# Get version info
backend_get_version_info() {
    local version="${OS_PRETTY_NAME:-Fedora $OS_VERSION_ID}"
    echo "$version"
}

# Check for RPM Fusion repositories
backend_has_rpmfusion() {
    rpm -q rpmfusion-free-release &>/dev/null || \
    rpm -q rpmfusion-nonfree-release &>/dev/null
}

# Enable RPM Fusion repositories
backend_enable_rpmfusion() {
    log_info "Enabling RPM Fusion repositories"

    if backend_has_rpmfusion; then
        log_debug "RPM Fusion already enabled"
        return 0
    fi

    local version="$OS_VERSION_ID"

    if have_cmd dnf; then
        run_as_root dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${version}.noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${version}.noarch.rpm"
    fi

    return 0
}

# Install group packages
backend_install_group() {
    local group="$1"

    log_info "Installing group: $group"

    if have_cmd dnf; then
        run_as_root dnf group install -y "$group"
    else
        run_as_root yum groupinstall -y "$group"
    fi
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

# Check if RHEL-based (not Fedora)
backend_is_rhel() {
    case "${OS_ID,,}" in
        rhel|centos|rocky|alma|almalinux|oracle)
            return 0
            ;;
    esac
    return 1
}

# Enable EPEL repository (for RHEL-based)
backend_enable_epel() {
    if ! backend_is_rhel; then
        log_debug "EPEL not needed for Fedora"
        return 0
    fi

    log_info "Enabling EPEL repository"

    if have_cmd dnf; then
        run_as_root dnf install -y epel-release
    else
        run_as_root yum install -y epel-release
    fi

    return 0
}

# Optimization hooks
backend_optimize_kernel() {
    log_info "Applying Fedora kernel optimizations"
    return 0
}

backend_optimize_services() {
    log_info "Optimizing Fedora services"
    return 0
}

# Print backend info
backend_print_info() {
    echo "Backend: $BACKEND_DISPLAY_NAME"
    echo "  Version: $(backend_get_version_info)"
    echo "  RHEL-based: $(backend_is_rhel && echo 'yes' || echo 'no')"
    echo "  RPM Fusion: $(backend_has_rpmfusion && echo 'enabled' || echo 'disabled')"
    echo "  Flatpak: $(have_cmd flatpak && echo 'available' || echo 'not found')"
}
