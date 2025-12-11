#!/usr/bin/env bash
#
# build.sh - Local build system for ultimate-linux-suite
#
# Usage:
#   ./build.sh deb    - Build .deb package
#   ./build.sh rpm    - Build .rpm package
#   ./build.sh all    - Build both .deb and .rpm
#   ./build.sh clean  - Clean build artifacts
#

set -euo pipefail

# Avoid dpkg-buildpackage recursion: if we are already inside a Debian build,
# don't let build.sh call dpkg-buildpackage again.
if [ "${ULS_INSIDE_DPKG_BUILD:-0}" = "1" ]; then
    export ULS_SKIP_DPKG_RECURSION=1
fi

# Get script directory (repo root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Package info
PKG_NAME="ultimate-linux-suite"

# Read version from VERSION file (single source of truth)
if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
    PKG_VERSION="$(cat "$SCRIPT_DIR/VERSION" | tr -d '[:space:]')"
else
    PKG_VERSION="1.0.0"
    echo "Warning: VERSION file not found, using default $PKG_VERSION" >&2
fi

# Color output (fallback gracefully)
setup_colors() {
    if command -v tput &>/dev/null && [[ -t 1 ]]; then
        RED=$(tput setaf 1)
        GREEN=$(tput setaf 2)
        YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4)
        BOLD=$(tput bold)
        RESET=$(tput sgr0)
    else
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        BOLD=""
        RESET=""
    fi
}

setup_colors

# Logging functions
log_info() {
    echo "${BLUE}[INFO]${RESET} $*"
}

log_success() {
    echo "${GREEN}[OK]${RESET} $*"
}

log_warn() {
    echo "${YELLOW}[WARN]${RESET} $*"
}

log_error() {
    echo "${RED}[ERROR]${RESET} $*"
}

log_cmd() {
    echo "${BOLD}>>> $*${RESET}"
}

# Show usage
usage() {
    cat <<EOF
${BOLD}Ultimate Linux Suite - Local Build System${RESET}

${BOLD}Usage:${RESET}
    $0 <command>

${BOLD}Commands:${RESET}
    deb     Build .deb package (requires dpkg-buildpackage)
    rpm     Build .rpm package (requires rpmbuild)
    all     Build both .deb and .rpm packages
    clean   Clean build artifacts

${BOLD}Examples:${RESET}
    $0 deb      # Build Debian package
    $0 rpm      # Build RPM package
    $0 all      # Build both packages
    $0 clean    # Clean up build files

${BOLD}Requirements:${RESET}
    For .deb: dpkg-dev, debhelper (install: sudo apt install dpkg-dev debhelper)
    For .rpm: rpm-build (install: sudo dnf install rpm-build)
EOF
}

# Build .deb package
build_deb() {
    log_info "Building .deb package..."

    # RECURSION GUARD: Check if we should skip dpkg-buildpackage call
    if [ "${ULS_SKIP_DPKG_RECURSION:-0}" = "1" ]; then
        log_info "Already inside dpkg-buildpackage context; skipping recursive dpkg-buildpackage call."
        return 0
    fi

    # Additional guard: dpkg-buildpackage sets DEB_BUILD_ARCH
    if [[ -n "${DEB_BUILD_ARCH:-}" ]]; then
        log_info "Detected DEB_BUILD_ARCH='$DEB_BUILD_ARCH' - already inside dpkg-buildpackage."
        log_info "Skipping nested dpkg-buildpackage call to prevent recursion."
        return 0
    fi

    # Check for dpkg-buildpackage
    if ! command -v dpkg-buildpackage &>/dev/null; then
        log_error "dpkg-buildpackage not found."
        log_error "Please install dpkg-dev: sudo apt install dpkg-dev debhelper"
        return 1
    fi

    # Create debian symlink if not exists
    if [[ ! -e "$SCRIPT_DIR/debian" ]]; then
        log_info "Creating debian/ symlink -> packaging/debian/"
        ln -sf packaging/debian "$SCRIPT_DIR/debian"
    fi

    # Run dpkg-buildpackage
    log_cmd "dpkg-buildpackage -us -uc -b"
    dpkg-buildpackage -us -uc -b

    # Find and report the .deb file
    local deb_file
    deb_file=$(find "$SCRIPT_DIR/.." -maxdepth 1 -name "${PKG_NAME}_*.deb" -type f 2>/dev/null | head -1)

    if [[ -n "$deb_file" && -f "$deb_file" ]]; then
        log_success "Debian package built successfully!"
        log_info "Package location: ${BOLD}$deb_file${RESET}"
    else
        log_warn "Build completed but .deb file not found in parent directory."
    fi

    return 0
}

# Build .rpm package
build_rpm() {
    log_info "Building .rpm package..."

    # Check for rpmbuild
    if ! command -v rpmbuild &>/dev/null; then
        log_error "rpmbuild not found."
        log_error "Please install rpm-build:"
        log_error "  Fedora/RHEL: sudo dnf install rpm-build"
        log_error "  openSUSE: sudo zypper install rpm-build"
        return 1
    fi

    local rpmbuild_dir="$HOME/rpmbuild"
    local tarball_name="${PKG_NAME}-${PKG_VERSION}.tar.gz"

    # Create rpmbuild directory structure
    log_info "Setting up rpmbuild directory structure..."
    for subdir in BUILD RPMS SOURCES SPECS SRPMS; do
        if [[ ! -d "$rpmbuild_dir/$subdir" ]]; then
            log_cmd "mkdir -p $rpmbuild_dir/$subdir"
            mkdir -p "$rpmbuild_dir/$subdir"
        fi
    done

    # Create source tarball
    # RPM %setup -q expects tarball to extract to PKG_NAME-VERSION directory
    log_info "Creating source tarball: $tarball_name"

    local temp_dir
    temp_dir=$(mktemp -d)
    local pkg_dir="$temp_dir/${PKG_NAME}-${PKG_VERSION}"

    # Copy source to temp directory with correct name
    log_cmd "Copying source to $pkg_dir"
    mkdir -p "$pkg_dir"

    # Copy all files except .git and build artifacts
    rsync -a --exclude='.git' --exclude='debian' --exclude='*.deb' \
          --exclude='*.rpm' --exclude='*.tar.gz' \
          "$SCRIPT_DIR/" "$pkg_dir/"

    # Create tarball
    log_cmd "tar czf $rpmbuild_dir/SOURCES/$tarball_name -C $temp_dir ${PKG_NAME}-${PKG_VERSION}"
    tar czf "$rpmbuild_dir/SOURCES/$tarball_name" -C "$temp_dir" "${PKG_NAME}-${PKG_VERSION}"

    # Cleanup temp directory
    rm -rf "$temp_dir"

    # Run rpmbuild
    log_cmd "rpmbuild -ba $SCRIPT_DIR/packaging/rpm/${PKG_NAME}.spec"
    rpmbuild -ba "$SCRIPT_DIR/packaging/rpm/${PKG_NAME}.spec"

    # Find and report the .rpm files
    log_success "RPM package built successfully!"
    log_info "RPM package locations:"

    local rpm_files
    rpm_files=$(find "$rpmbuild_dir/RPMS" -name "*.rpm" -type f 2>/dev/null)
    if [[ -n "$rpm_files" ]]; then
        echo "$rpm_files" | while read -r rpm; do
            log_info "  ${BOLD}$rpm${RESET}"
        done
    fi

    local srpm_files
    srpm_files=$(find "$rpmbuild_dir/SRPMS" -name "*.rpm" -type f 2>/dev/null)
    if [[ -n "$srpm_files" ]]; then
        log_info "Source RPM:"
        echo "$srpm_files" | while read -r srpm; do
            log_info "  ${BOLD}$srpm${RESET}"
        done
    fi

    return 0
}

# Build all packages
build_all() {
    local deb_status=0
    local rpm_status=0

    log_info "Building all packages..."
    echo

    # Try to build deb
    if command -v dpkg-buildpackage &>/dev/null; then
        build_deb || deb_status=$?
        echo
    else
        log_warn "Skipping .deb build (dpkg-buildpackage not available)"
        deb_status=1
    fi

    # Try to build rpm
    if command -v rpmbuild &>/dev/null; then
        build_rpm || rpm_status=$?
        echo
    else
        log_warn "Skipping .rpm build (rpmbuild not available)"
        rpm_status=1
    fi

    # Summary
    echo "${BOLD}Build Summary:${RESET}"
    if [[ $deb_status -eq 0 ]]; then
        log_success ".deb build: SUCCESS"
    else
        log_error ".deb build: FAILED or SKIPPED"
    fi

    if [[ $rpm_status -eq 0 ]]; then
        log_success ".rpm build: SUCCESS"
    else
        log_error ".rpm build: FAILED or SKIPPED"
    fi

    # Return failure if both failed
    if [[ $deb_status -ne 0 && $rpm_status -ne 0 ]]; then
        return 1
    fi

    return 0
}

# Clean build artifacts
clean_build() {
    log_info "Cleaning build artifacts..."

    # Clean Debian build artifacts in parent directory
    local parent_dir="$SCRIPT_DIR/.."
    local cleaned=0

    # .deb files
    for pattern in "${PKG_NAME}_*.deb" "${PKG_NAME}_*.build" "${PKG_NAME}_*.buildinfo" \
                   "${PKG_NAME}_*.changes" "${PKG_NAME}_*.dsc" "${PKG_NAME}_*.tar.*"; do
        for file in "$parent_dir"/$pattern; do
            if [[ -f "$file" ]]; then
                log_cmd "rm $file"
                rm -f "$file"
                ((cleaned++))
            fi
        done
    done

    # NOTE: Do NOT remove the debian symlink here - it breaks dpkg-buildpackage
    # when dh_auto_clean calls this script. The debian symlink is intentionally
    # preserved to allow the build to complete.

    # Clean any local .deb or .rpm files
    for file in "$SCRIPT_DIR"/*.deb "$SCRIPT_DIR"/*.rpm; do
        if [[ -f "$file" ]]; then
            log_cmd "rm $file"
            rm -f "$file"
            ((cleaned++))
        fi
    done

    if [[ $cleaned -gt 0 ]]; then
        log_success "Cleaned $cleaned build artifact(s)."
    else
        log_info "No build artifacts found to clean."
    fi

    # RPM cleanup instructions
    echo
    log_info "Note: RPM build artifacts are stored in ~/rpmbuild/"
    log_info "To clean RPM artifacts manually, run:"
    echo "    rm -rf ~/rpmbuild/BUILD/${PKG_NAME}-*"
    echo "    rm -f ~/rpmbuild/SOURCES/${PKG_NAME}-*.tar.gz"
    echo "    rm -f ~/rpmbuild/RPMS/*/${PKG_NAME}-*.rpm"
    echo "    rm -f ~/rpmbuild/SRPMS/${PKG_NAME}-*.rpm"
    echo
    log_info "Or to remove entire rpmbuild tree: rm -rf ~/rpmbuild"

    return 0
}

# Main
main() {
    local cmd="${1:-}"

    case "$cmd" in
        deb)
            build_deb
            ;;
        rpm)
            build_rpm
            ;;
        all)
            build_all
            ;;
        clean)
            clean_build
            ;;
        -h|--help|help)
            usage
            ;;
        "")
            log_error "No command specified."
            echo
            usage
            exit 1
            ;;
        *)
            log_error "Unknown command: $cmd"
            echo
            usage
            exit 1
            ;;
    esac
}

main "$@"
