#!/usr/bin/env bash
#
# arch.sh - Arch Linux Backend for Ultimate Linux Suite
#
# Provides Arch and Arch-based distro functionality
# Covers: Arch, Manjaro, EndeavourOS, Garuda, ArcoLinux
#

# Prevent multiple sourcing
[[ -n "${_BACKEND_ARCH_LOADED:-}" ]] && return 0
readonly _BACKEND_ARCH_LOADED=1

# Backend identification
readonly BACKEND_NAME="arch"
readonly BACKEND_DISPLAY_NAME="Arch Linux"
readonly BACKEND_FAMILY="arch"

# Initialize Arch backend
backend_init() {
    log_info "Initializing Arch backend"

    if ! have_cmd pacman; then
        log_error "pacman not found - this doesn't appear to be Arch"
        return 1
    fi

    # Check for AUR helpers
    local aur_helpers=("yay" "paru" "pikaur" "trizen" "pamac")
    for helper in "${aur_helpers[@]}"; do
        if have_cmd "$helper"; then
            log_debug "Found AUR helper: $helper"
            break
        fi
    done

    log_debug "Arch backend initialized"
    return 0
}

# Install packages
backend_install_packages() {
    local packages=("$@")

    log_info "Installing packages: ${packages[*]}"

    run_as_root pacman -S --noconfirm --needed "${packages[@]}"
}

# Post-setup tasks
backend_post_setup() {
    log_info "Running Arch post-setup tasks"

    # Clean package cache (keep last 2 versions)
    if have_cmd paccache; then
        run_as_root paccache -rk2
    fi

    # Remove orphaned packages
    local orphans
    orphans=$(pacman -Qdtq 2>/dev/null)
    if [[ -n "$orphans" ]]; then
        run_as_root pacman -Rns --noconfirm $orphans
    fi

    log_debug "Arch post-setup complete"
    return 0
}

# Get version info
backend_get_version_info() {
    local version="${OS_PRETTY_NAME:-Arch Linux}"
    echo "$version (rolling)"
}

# Get available AUR helper
backend_get_aur_helper() {
    local helpers=("yay" "paru" "pikaur" "trizen")
    for helper in "${helpers[@]}"; do
        if have_cmd "$helper"; then
            echo "$helper"
            return 0
        fi
    done
    return 1
}

# Install AUR packages
backend_install_aur() {
    local packages=("$@")
    local helper

    helper=$(backend_get_aur_helper)
    if [[ -z "$helper" ]]; then
        log_warn "No AUR helper found"
        return 1
    fi

    log_info "Installing AUR packages with $helper: ${packages[*]}"

    case "$helper" in
        yay|paru)
            "$helper" -S --noconfirm --needed "${packages[@]}"
            ;;
        pikaur|trizen)
            "$helper" -S --noconfirm "${packages[@]}"
            ;;
    esac
}

# Check if multilib is enabled
backend_has_multilib() {
    grep -q '^\[multilib\]' /etc/pacman.conf 2>/dev/null
}

# Enable multilib repository
backend_enable_multilib() {
    log_info "Enabling multilib repository"

    if backend_has_multilib; then
        log_debug "Multilib already enabled"
        return 0
    fi

    # Enable multilib in pacman.conf
    run_as_root sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
    run_as_root pacman -Sy

    return 0
}

# System update
backend_system_update() {
    log_info "Updating Arch system"

    run_as_root pacman -Syu --noconfirm

    # Also update AUR if helper available
    local helper
    helper=$(backend_get_aur_helper)
    if [[ -n "$helper" ]]; then
        "$helper" -Sua --noconfirm
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

# Check if this is a specific Arch derivative
backend_is_manjaro() {
    [[ "${OS_ID,,}" == "manjaro" ]]
}

backend_is_endeavouros() {
    [[ "${OS_ID,,}" == "endeavouros" ]]
}

# Optimization hooks
backend_optimize_kernel() {
    log_info "Applying Arch kernel optimizations"
    return 0
}

backend_optimize_services() {
    log_info "Optimizing Arch services"
    return 0
}

# Print backend info
backend_print_info() {
    local aur_helper
    aur_helper=$(backend_get_aur_helper)

    echo "Backend: $BACKEND_DISPLAY_NAME"
    echo "  Version: $(backend_get_version_info)"
    echo "  AUR Helper: ${aur_helper:-none}"
    echo "  Multilib: $(backend_has_multilib && echo 'enabled' || echo 'disabled')"
    echo "  Flatpak: $(have_cmd flatpak && echo 'available' || echo 'not found')"
}
