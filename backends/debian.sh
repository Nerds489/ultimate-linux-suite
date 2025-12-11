#!/usr/bin/env bash
#
# debian.sh - Debian Backend for Ultimate Linux Suite
#
# Provides Debian-specific functionality and optimizations
#

# Prevent multiple sourcing
[[ -n "${_BACKEND_DEBIAN_LOADED:-}" ]] && return 0
readonly _BACKEND_DEBIAN_LOADED=1

# Backend identification
readonly BACKEND_NAME="debian"
readonly BACKEND_DISPLAY_NAME="Debian"
readonly BACKEND_FAMILY="debian"

# Initialize Debian backend
backend_init() {
    log_info "Initializing Debian backend"

    # Verify we're on Debian
    if [[ "$OS_ID" != "debian" ]]; then
        log_warn "Debian backend loaded but OS is $OS_ID"
    fi

    # Check for essential Debian tools
    local tools=("apt" "dpkg" "apt-cache")
    for tool in "${tools[@]}"; do
        if ! have_cmd "$tool"; then
            log_warn "Debian tool not found: $tool"
        fi
    done

    log_debug "Debian backend initialized"
    return 0
}

# Install packages using apt
backend_install_packages() {
    local packages=("$@")

    log_info "Installing packages: ${packages[*]}"

    run_as_root apt update || log_warn "apt update had issues"
    run_as_root apt install -y "${packages[@]}"
}

# Debian-specific post-setup tasks
backend_post_setup() {
    log_info "Running Debian post-setup tasks"

    # Clean apt cache
    run_as_root apt autoremove -y
    run_as_root apt clean

    log_debug "Debian post-setup complete"
    return 0
}

# Get Debian version info
backend_get_version_info() {
    local debian_version=""

    if [[ -f /etc/debian_version ]]; then
        debian_version=$(cat /etc/debian_version)
    fi

    echo "Debian ${debian_version:-$OS_VERSION_ID}"
}

# Check for non-free repositories
backend_has_nonfree() {
    grep -qE 'contrib|non-free' /etc/apt/sources.list 2>/dev/null || \
    grep -rqE 'contrib|non-free' /etc/apt/sources.list.d/ 2>/dev/null
}

# Enable non-free repositories
backend_enable_nonfree() {
    log_info "Enabling non-free repositories"

    if backend_has_nonfree; then
        log_debug "Non-free repositories already enabled"
        return 0
    fi

    # This is a safe operation that adds non-free to existing sources
    local sources_file="/etc/apt/sources.list"
    if [[ -f "$sources_file" ]]; then
        run_as_root sed -i 's/main$/main contrib non-free/g' "$sources_file"
        run_as_root apt update
    fi

    return 0
}

# Debian-specific optimization hooks
backend_optimize_kernel() {
    log_info "Applying Debian kernel optimizations"
    # Placeholder for kernel optimizations
    return 0
}

backend_optimize_services() {
    log_info "Optimizing Debian services"
    # Placeholder for service optimizations
    return 0
}

# Print backend info
backend_print_info() {
    echo "Backend: $BACKEND_DISPLAY_NAME"
    echo "  Version: $(backend_get_version_info)"
    echo "  Non-free repos: $(backend_has_nonfree && echo 'enabled' || echo 'disabled')"
}
