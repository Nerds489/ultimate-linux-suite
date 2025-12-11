#!/usr/bin/env bash
#
# mint.sh - Linux Mint Backend for Ultimate Linux Suite
#
# Provides Linux Mint and LMDE-specific functionality
#

# Prevent multiple sourcing
[[ -n "${_BACKEND_MINT_LOADED:-}" ]] && return 0
readonly _BACKEND_MINT_LOADED=1

# Backend identification
readonly BACKEND_NAME="mint"
readonly BACKEND_DISPLAY_NAME="Linux Mint"
readonly BACKEND_FAMILY="debian"

# Initialize Mint backend
backend_init() {
    log_info "Initializing Linux Mint backend"

    local tools=("apt" "dpkg" "mintupdate" "mintinstall")
    for tool in "${tools[@]}"; do
        if ! have_cmd "$tool"; then
            log_debug "Mint tool not available: $tool"
        fi
    done

    log_debug "Linux Mint backend initialized"
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
    log_info "Running Linux Mint post-setup tasks"

    run_as_root apt autoremove -y
    run_as_root apt clean

    log_debug "Linux Mint post-setup complete"
    return 0
}

# Get version info
backend_get_version_info() {
    local version="${OS_PRETTY_NAME:-Linux Mint $OS_VERSION_ID}"
    echo "$version"
}

# Check if LMDE (Debian Edition)
backend_is_lmde() {
    [[ "${OS_ID,,}" == "lmde" ]] || \
    [[ "${OS_NAME,,}" == *"lmde"* ]]
}

# Install Flatpak packages (Mint prefers Flatpak over Snap)
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

# Update system using mintupdate if available
backend_system_update() {
    log_info "Updating Linux Mint system"

    if have_cmd mintupdate-cli; then
        run_as_root mintupdate-cli upgrade -y
    else
        run_as_root apt update
        run_as_root apt upgrade -y
    fi

    return 0
}

# Optimization hooks
backend_optimize_kernel() {
    log_info "Applying Linux Mint kernel optimizations"
    return 0
}

backend_optimize_services() {
    log_info "Optimizing Linux Mint services"
    return 0
}

# Print backend info
backend_print_info() {
    echo "Backend: $BACKEND_DISPLAY_NAME"
    echo "  Version: $(backend_get_version_info)"
    echo "  LMDE: $(backend_is_lmde && echo 'yes' || echo 'no')"
    echo "  Flatpak: $(have_cmd flatpak && echo 'available' || echo 'not found')"
}
