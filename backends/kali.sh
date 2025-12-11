#!/usr/bin/env bash
#
# kali.sh - Kali Linux Backend for Ultimate Linux Suite
#
# Provides Kali Linux specific functionality
#

# Prevent multiple sourcing
[[ -n "${_BACKEND_KALI_LOADED:-}" ]] && return 0
readonly _BACKEND_KALI_LOADED=1

# Backend identification
readonly BACKEND_NAME="kali"
readonly BACKEND_DISPLAY_NAME="Kali Linux"
readonly BACKEND_FAMILY="debian"

# Initialize Kali backend
backend_init() {
    log_info "Initializing Kali Linux backend"

    local tools=("apt" "dpkg" "kali-tweaks")
    for tool in "${tools[@]}"; do
        if ! have_cmd "$tool"; then
            log_debug "Kali tool not available: $tool"
        fi
    done

    log_debug "Kali backend initialized"
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
    log_info "Running Kali post-setup tasks"

    run_as_root apt autoremove -y
    run_as_root apt clean

    log_debug "Kali post-setup complete"
    return 0
}

# Get version info
backend_get_version_info() {
    local version="${OS_PRETTY_NAME:-Kali Linux $OS_VERSION_ID}"
    echo "$version"
}

# Install Kali metapackages
backend_install_metapackage() {
    local metapkg="$1"

    log_info "Installing Kali metapackage: $metapkg"

    run_as_root apt install -y "$metapkg"
}

# Available Kali metapackages
backend_list_metapackages() {
    local metapackages=(
        "kali-linux-core"
        "kali-linux-default"
        "kali-linux-large"
        "kali-linux-everything"
        "kali-tools-top10"
        "kali-tools-web"
        "kali-tools-wireless"
        "kali-tools-forensics"
        "kali-tools-exploitation"
        "kali-tools-passwords"
        "kali-tools-sniffing-spoofing"
    )

    printf '%s\n' "${metapackages[@]}"
}

# Check if running as default user
backend_is_default_user() {
    [[ "$(whoami)" == "kali" ]]
}

# System update
backend_system_update() {
    log_info "Updating Kali system"

    run_as_root apt update
    run_as_root apt full-upgrade -y

    return 0
}

# Optimization hooks
backend_optimize_kernel() {
    log_info "Applying Kali kernel optimizations"
    return 0
}

backend_optimize_services() {
    log_info "Optimizing Kali services"
    return 0
}

# Print backend info
backend_print_info() {
    echo "Backend: $BACKEND_DISPLAY_NAME"
    echo "  Version: $(backend_get_version_info)"
    echo "  kali-tweaks: $(have_cmd kali-tweaks && echo 'available' || echo 'not found')"
}
