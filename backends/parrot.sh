#!/usr/bin/env bash
#
# parrot.sh - Parrot OS Backend for Ultimate Linux Suite
#
# Provides Parrot OS specific functionality
#

# Prevent multiple sourcing
[[ -n "${_BACKEND_PARROT_LOADED:-}" ]] && return 0
readonly _BACKEND_PARROT_LOADED=1

# Backend identification
readonly BACKEND_NAME="parrot"
readonly BACKEND_DISPLAY_NAME="Parrot OS"
readonly BACKEND_FAMILY="debian"

# Initialize Parrot backend
backend_init() {
    log_info "Initializing Parrot OS backend"

    local tools=("apt" "dpkg" "parrot-upgrade")
    for tool in "${tools[@]}"; do
        if ! have_cmd "$tool"; then
            log_debug "Parrot tool not available: $tool"
        fi
    done

    log_debug "Parrot backend initialized"
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
    log_info "Running Parrot post-setup tasks"

    run_as_root apt autoremove -y
    run_as_root apt clean

    log_debug "Parrot post-setup complete"
    return 0
}

# Get version info
backend_get_version_info() {
    local version="${OS_PRETTY_NAME:-Parrot OS $OS_VERSION_ID}"
    echo "$version"
}

# Parrot editions
backend_get_edition() {
    local edition="unknown"

    if dpkg -l parrot-interface-full &>/dev/null; then
        edition="Home"
    elif dpkg -l parrot-tools-full &>/dev/null; then
        edition="Security"
    elif dpkg -l parrot-interface-common &>/dev/null; then
        edition="Minimal"
    fi

    echo "$edition"
}

# Install Parrot metapackages
backend_install_metapackage() {
    local metapkg="$1"

    log_info "Installing Parrot metapackage: $metapkg"

    run_as_root apt install -y "$metapkg"
}

# Available Parrot metapackages
backend_list_metapackages() {
    local metapackages=(
        "parrot-tools-full"
        "parrot-tools-common"
        "parrot-tools-cloud"
        "parrot-tools-automotive"
        "parrot-tools-pwn"
        "parrot-tools-web"
        "parrot-tools-wifi"
        "parrot-tools-forensics"
        "parrot-tools-crypto"
        "parrot-tools-infogathering"
    )

    printf '%s\n' "${metapackages[@]}"
}

# System update using parrot-upgrade if available
backend_system_update() {
    log_info "Updating Parrot system"

    if have_cmd parrot-upgrade; then
        run_as_root parrot-upgrade -y
    else
        run_as_root apt update
        run_as_root apt full-upgrade -y
    fi

    return 0
}

# Optimization hooks
backend_optimize_kernel() {
    log_info "Applying Parrot kernel optimizations"
    return 0
}

backend_optimize_services() {
    log_info "Optimizing Parrot services"
    return 0
}

# Print backend info
backend_print_info() {
    echo "Backend: $BACKEND_DISPLAY_NAME"
    echo "  Version: $(backend_get_version_info)"
    echo "  Edition: $(backend_get_edition)"
    echo "  parrot-upgrade: $(have_cmd parrot-upgrade && echo 'available' || echo 'not found')"
}
