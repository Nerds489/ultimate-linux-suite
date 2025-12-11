#!/usr/bin/env bash
#
# pkg.sh - Package Manager Abstraction for Ultimate Linux Suite
#
# Provides unified package management across different distributions
# Supports native packages, Flatpak, and Snap
#

# Prevent multiple sourcing
[[ -n "${_PKG_SH_LOADED:-}" ]] && return 0
readonly _PKG_SH_LOADED=1

# ============================================================================
# FLATPAK & SNAP SUPPORT FLAGS
# ============================================================================

# Flatpak support
FLATPAK_AVAILABLE=0
FLATPAK_ENABLED=0
FLATHUB_CONFIGURED=0

# Snap support
SNAP_AVAILABLE=0
SNAP_ENABLED=0

# ============================================================================
# PACKAGE NAME MAPPINGS
# ============================================================================

# Format: PACKAGE_MAP[generic_name]="apt:apt_name|dnf:dnf_name|pacman:pacman_name|zypper:zypper_name"
declare -gA PACKAGE_MAP=(
    # Build essentials
    ["build-essential"]="apt:build-essential|dnf:@development-tools|pacman:base-devel|zypper:-t pattern devel_basis"
    ["base-devel"]="apt:build-essential|dnf:@development-tools|pacman:base-devel|zypper:-t pattern devel_basis"

    # Core utilities
    ["vim"]="apt:vim|dnf:vim-enhanced|pacman:vim|zypper:vim"
    ["neovim"]="apt:neovim|dnf:neovim|pacman:neovim|zypper:neovim"
    ["git"]="apt:git|dnf:git|pacman:git|zypper:git"
    ["git-lfs"]="apt:git-lfs|dnf:git-lfs|pacman:git-lfs|zypper:git-lfs"
    ["curl"]="apt:curl|dnf:curl|pacman:curl|zypper:curl"
    ["wget"]="apt:wget|dnf:wget|pacman:wget|zypper:wget"
    ["htop"]="apt:htop|dnf:htop|pacman:htop|zypper:htop"
    ["btop"]="apt:btop|dnf:btop|pacman:btop|zypper:btop"
    ["neofetch"]="apt:neofetch|dnf:neofetch|pacman:neofetch|zypper:neofetch"
    ["fastfetch"]="apt:fastfetch|dnf:fastfetch|pacman:fastfetch|zypper:fastfetch"
    ["dialog"]="apt:dialog|dnf:dialog|pacman:dialog|zypper:dialog"
    ["whiptail"]="apt:whiptail|dnf:newt|pacman:libnewt|zypper:newt"
    ["tmux"]="apt:tmux|dnf:tmux|pacman:tmux|zypper:tmux"
    ["screen"]="apt:screen|dnf:screen|pacman:screen|zypper:screen"
    ["tree"]="apt:tree|dnf:tree|pacman:tree|zypper:tree"
    ["ncdu"]="apt:ncdu|dnf:ncdu|pacman:ncdu|zypper:ncdu"
    ["mc"]="apt:mc|dnf:mc|pacman:mc|zypper:mc"
    ["jq"]="apt:jq|dnf:jq|pacman:jq|zypper:jq"
    ["fzf"]="apt:fzf|dnf:fzf|pacman:fzf|zypper:fzf"
    ["ripgrep"]="apt:ripgrep|dnf:ripgrep|pacman:ripgrep|zypper:ripgrep"
    ["fd-find"]="apt:fd-find|dnf:fd-find|pacman:fd|zypper:fd"
    ["bat"]="apt:bat|dnf:bat|pacman:bat|zypper:bat"
    ["exa"]="apt:exa|dnf:exa|pacman:exa|zypper:exa"
    ["zoxide"]="apt:zoxide|dnf:zoxide|pacman:zoxide|zypper:zoxide"

    # Python
    ["python3"]="apt:python3|dnf:python3|pacman:python|zypper:python3"
    ["python3-pip"]="apt:python3-pip|dnf:python3-pip|pacman:python-pip|zypper:python3-pip"
    ["python3-venv"]="apt:python3-venv|dnf:python3-virtualenv|pacman:python-virtualenv|zypper:python3-virtualenv"
    ["python3-dev"]="apt:python3-dev|dnf:python3-devel|pacman:python|zypper:python3-devel"

    # Node.js
    ["nodejs"]="apt:nodejs|dnf:nodejs|pacman:nodejs|zypper:nodejs"
    ["npm"]="apt:npm|dnf:npm|pacman:npm|zypper:npm"

    # Compilers & Tools
    ["gcc"]="apt:gcc|dnf:gcc|pacman:gcc|zypper:gcc"
    ["g++"]="apt:g++|dnf:gcc-c++|pacman:gcc|zypper:gcc-c++"
    ["make"]="apt:make|dnf:make|pacman:make|zypper:make"
    ["cmake"]="apt:cmake|dnf:cmake|pacman:cmake|zypper:cmake"
    ["meson"]="apt:meson|dnf:meson|pacman:meson|zypper:meson"
    ["ninja"]="apt:ninja-build|dnf:ninja-build|pacman:ninja|zypper:ninja"
    ["gdb"]="apt:gdb|dnf:gdb|pacman:gdb|zypper:gdb"
    ["valgrind"]="apt:valgrind|dnf:valgrind|pacman:valgrind|zypper:valgrind"
    ["strace"]="apt:strace|dnf:strace|pacman:strace|zypper:strace"

    # Go & Rust
    ["golang"]="apt:golang|dnf:golang|pacman:go|zypper:go"
    ["rust"]="apt:rustc|dnf:rust|pacman:rust|zypper:rust"
    ["cargo"]="apt:cargo|dnf:cargo|pacman:rust|zypper:cargo"

    # Containers
    ["docker"]="apt:docker.io|dnf:docker|pacman:docker|zypper:docker"
    ["docker-compose"]="apt:docker-compose|dnf:docker-compose|pacman:docker-compose|zypper:docker-compose"
    ["podman"]="apt:podman|dnf:podman|pacman:podman|zypper:podman"

    # Web Browsers
    ["firefox"]="apt:firefox|dnf:firefox|pacman:firefox|zypper:MozillaFirefox"
    ["chromium"]="apt:chromium-browser|dnf:chromium|pacman:chromium|zypper:chromium"
    ["firefox-esr"]="apt:firefox-esr|dnf:firefox|pacman:firefox|zypper:MozillaFirefox"

    # Media
    ["vlc"]="apt:vlc|dnf:vlc|pacman:vlc|zypper:vlc"
    ["mpv"]="apt:mpv|dnf:mpv|pacman:mpv|zypper:mpv"
    ["ffmpeg"]="apt:ffmpeg|dnf:ffmpeg|pacman:ffmpeg|zypper:ffmpeg"
    ["audacity"]="apt:audacity|dnf:audacity|pacman:audacity|zypper:audacity"

    # Graphics
    ["gimp"]="apt:gimp|dnf:gimp|pacman:gimp|zypper:gimp"
    ["inkscape"]="apt:inkscape|dnf:inkscape|pacman:inkscape|zypper:inkscape"
    ["krita"]="apt:krita|dnf:krita|pacman:krita|zypper:krita"
    ["blender"]="apt:blender|dnf:blender|pacman:blender|zypper:blender"
    ["imagemagick"]="apt:imagemagick|dnf:ImageMagick|pacman:imagemagick|zypper:ImageMagick"

    # Office
    ["libreoffice"]="apt:libreoffice|dnf:libreoffice|pacman:libreoffice-fresh|zypper:libreoffice"
    ["thunderbird"]="apt:thunderbird|dnf:thunderbird|pacman:thunderbird|zypper:MozillaThunderbird"
    ["evince"]="apt:evince|dnf:evince|pacman:evince|zypper:evince"
    ["okular"]="apt:okular|dnf:okular|pacman:okular|zypper:okular"

    # Gaming
    ["steam"]="apt:steam|dnf:steam|pacman:steam|zypper:steam"
    ["lutris"]="apt:lutris|dnf:lutris|pacman:lutris|zypper:lutris"
    ["wine"]="apt:wine|dnf:wine|pacman:wine|zypper:wine"
    ["wine-staging"]="apt:wine-staging|dnf:wine-staging|pacman:wine-staging|zypper:wine-staging"
    ["gamemode"]="apt:gamemode|dnf:gamemode|pacman:gamemode|zypper:gamemode"
    ["mangohud"]="apt:mangohud|dnf:mangohud|pacman:mangohud|zypper:mangohud"

    # Communication
    ["telegram-desktop"]="apt:telegram-desktop|dnf:telegram-desktop|pacman:telegram-desktop|zypper:telegram-desktop"

    # System utilities
    ["gparted"]="apt:gparted|dnf:gparted|pacman:gparted|zypper:gparted"
    ["gnome-disk-utility"]="apt:gnome-disk-utility|dnf:gnome-disk-utility|pacman:gnome-disk-utility|zypper:gnome-disk-utility"
    ["timeshift"]="apt:timeshift|dnf:timeshift|pacman:timeshift|zypper:timeshift"
    ["bleachbit"]="apt:bleachbit|dnf:bleachbit|pacman:bleachbit|zypper:bleachbit"
    ["stacer"]="apt:stacer|dnf:stacer|pacman:stacer|zypper:stacer"

    # Network tools
    ["net-tools"]="apt:net-tools|dnf:net-tools|pacman:net-tools|zypper:net-tools"
    ["nmap"]="apt:nmap|dnf:nmap|pacman:nmap|zypper:nmap"
    ["wireshark"]="apt:wireshark|dnf:wireshark|pacman:wireshark-qt|zypper:wireshark"
    ["tcpdump"]="apt:tcpdump|dnf:tcpdump|pacman:tcpdump|zypper:tcpdump"
    ["openssh-client"]="apt:openssh-client|dnf:openssh-clients|pacman:openssh|zypper:openssh"
    ["openssh-server"]="apt:openssh-server|dnf:openssh-server|pacman:openssh|zypper:openssh"
    ["wireguard"]="apt:wireguard|dnf:wireguard-tools|pacman:wireguard-tools|zypper:wireguard-tools"
    ["tailscale"]="apt:tailscale|dnf:tailscale|pacman:tailscale|zypper:tailscale"
    ["rclone"]="apt:rclone|dnf:rclone|pacman:rclone|zypper:rclone"
    ["syncthing"]="apt:syncthing|dnf:syncthing|pacman:syncthing|zypper:syncthing"

    # Virtualization
    ["virtualbox"]="apt:virtualbox|dnf:VirtualBox|pacman:virtualbox|zypper:virtualbox"
    ["qemu"]="apt:qemu-system|dnf:qemu-kvm|pacman:qemu-full|zypper:qemu"
    ["virt-manager"]="apt:virt-manager|dnf:virt-manager|pacman:virt-manager|zypper:virt-manager"
    ["libvirt"]="apt:libvirt-daemon-system|dnf:libvirt|pacman:libvirt|zypper:libvirt"

    # Security
    ["clamav"]="apt:clamav|dnf:clamav|pacman:clamav|zypper:clamav"
    ["ufw"]="apt:ufw|dnf:ufw|pacman:ufw|zypper:ufw"
    ["fail2ban"]="apt:fail2ban|dnf:fail2ban|pacman:fail2ban|zypper:fail2ban"

    # Archive tools
    ["zip"]="apt:zip|dnf:zip|pacman:zip|zypper:zip"
    ["unzip"]="apt:unzip|dnf:unzip|pacman:unzip|zypper:unzip"
    ["p7zip"]="apt:p7zip-full|dnf:p7zip|pacman:p7zip|zypper:p7zip"
    ["unrar"]="apt:unrar|dnf:unrar|pacman:unrar|zypper:unrar"

    # Shell
    ["zsh"]="apt:zsh|dnf:zsh|pacman:zsh|zypper:zsh"
    ["fish"]="apt:fish|dnf:fish|pacman:fish|zypper:fish"
    ["bash-completion"]="apt:bash-completion|dnf:bash-completion|pacman:bash-completion|zypper:bash-completion"

    # Flatpak & Snap
    ["flatpak"]="apt:flatpak|dnf:flatpak|pacman:flatpak|zypper:flatpak"
    ["snapd"]="apt:snapd|dnf:snapd|pacman:snapd|zypper:snapd"
)

# Flatpak app ID mappings
declare -gA FLATPAK_MAP=(
    ["vscode"]="com.visualstudio.code"
    ["vscodium"]="com.vscodium.codium"
    ["firefox"]="org.mozilla.firefox"
    ["chromium"]="org.chromium.Chromium"
    ["chrome"]="com.google.Chrome"
    ["brave"]="com.brave.Browser"
    ["vivaldi"]="com.vivaldi.Vivaldi"
    ["opera"]="com.opera.Opera"
    ["ungoogled-chromium"]="com.github.AChep.ungoogled-chromium"
    ["vlc"]="org.videolan.VLC"
    ["mpv"]="io.mpv.Mpv"
    ["gimp"]="org.gimp.GIMP"
    ["inkscape"]="org.inkscape.Inkscape"
    ["krita"]="org.kde.krita"
    ["blender"]="org.blender.Blender"
    ["audacity"]="org.audacityteam.Audacity"
    ["obs-studio"]="com.obsproject.Studio"
    ["kdenlive"]="org.kde.kdenlive"
    ["libreoffice"]="org.libreoffice.LibreOffice"
    ["onlyoffice"]="org.onlyoffice.desktopeditors"
    ["thunderbird"]="org.mozilla.Thunderbird"
    ["steam"]="com.valvesoftware.Steam"
    ["lutris"]="net.lutris.Lutris"
    ["heroic"]="com.heroicgameslauncher.hgl"
    ["bottles"]="com.usebottles.bottles"
    ["protonup-qt"]="net.davidotek.pupgui2"
    ["discord"]="com.discordapp.Discord"
    ["slack"]="com.slack.Slack"
    ["zoom"]="us.zoom.Zoom"
    ["telegram"]="org.telegram.desktop"
    ["signal"]="org.signal.Signal"
    ["element"]="im.riot.Riot"
    ["obsidian"]="md.obsidian.Obsidian"
    ["joplin"]="net.cozic.joplin_desktop"
    ["spotify"]="com.spotify.Client"
    ["flatseal"]="com.github.tchx84.Flatseal"
    ["postman"]="com.getpostman.Postman"
    ["dbeaver"]="io.dbeaver.DBeaverCommunity"
    ["gittyup"]="com.github.Murmele.Gittyup"
)

# Snap app name mappings
declare -gA SNAP_MAP=(
    ["vscode"]="code --classic"
    ["spotify"]="spotify"
    ["discord"]="discord"
    ["slack"]="slack --classic"
    ["telegram"]="telegram-desktop"
    ["obs-studio"]="obs-studio"
    ["blender"]="blender --classic"
    ["chromium"]="chromium"
    ["firefox"]="firefox"
    ["vlc"]="vlc"
    ["gimp"]="gimp"
    ["inkscape"]="inkscape"
    ["kdenlive"]="kdenlive"
    ["postman"]="postman"
    ["docker"]="docker"
)

# ============================================================================
# INITIALIZATION
# ============================================================================

# Initialize package system
pkg_init() {
    # Detect Flatpak availability
    if have_cmd flatpak; then
        FLATPAK_AVAILABLE=1
        FLATPAK_ENABLED=1

        # Check if Flathub is configured
        if flatpak remote-list 2>/dev/null | grep -q "flathub"; then
            FLATHUB_CONFIGURED=1
        fi

        log_debug "Flatpak detected (Flathub: $FLATHUB_CONFIGURED)"
    fi

    # Detect Snap availability
    if have_cmd snap && systemctl is-active --quiet snapd 2>/dev/null; then
        SNAP_AVAILABLE=1
        # Snap disabled by default - user must enable
        SNAP_ENABLED=0
        log_debug "Snap detected (disabled by default)"
    fi

    log_debug "Package system initialized: PKG_MANAGER=$PKG_MANAGER, Flatpak=$FLATPAK_AVAILABLE, Snap=$SNAP_AVAILABLE"
}

# ============================================================================
# NATIVE PACKAGE FUNCTIONS
# ============================================================================

# Get distro-specific package name
get_package_name() {
    local generic="$1"

    if [[ -n "${PACKAGE_MAP[$generic]:-}" ]]; then
        local mapping="${PACKAGE_MAP[$generic]}"
        local pkg_name
        pkg_name=$(echo "$mapping" | tr '|' '\n' | grep "^${PKG_MANAGER}:" | cut -d: -f2)

        if [[ -n "$pkg_name" ]]; then
            echo "$pkg_name"
            return 0
        fi
    fi

    echo "$generic"
}

# Update package cache/indexes
pkg_update_indexes() {
    log_info "Updating package indexes..."

    case "$PKG_MANAGER" in
        apt)
            run_as_root apt update
            ;;
        dnf)
            run_as_root dnf check-update || true
            ;;
        yum)
            run_as_root yum check-update || true
            ;;
        pacman)
            run_as_root pacman -Sy
            ;;
        zypper)
            run_as_root zypper refresh
            ;;
        *)
            log_warn "Unknown package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
}

# Alias for backward compatibility
pkg_update() {
    pkg_update_indexes "$@"
}

# Install packages (native)
pkg_install() {
    local packages=("$@")
    local resolved_packages=()

    for pkg in "${packages[@]}"; do
        resolved_packages+=("$(get_package_name "$pkg")")
    done

    log_info "Installing: ${resolved_packages[*]}"

    case "$PKG_MANAGER" in
        apt)
            run_as_root apt install -y "${resolved_packages[@]}"
            ;;
        dnf)
            run_as_root dnf install -y "${resolved_packages[@]}"
            ;;
        yum)
            run_as_root yum install -y "${resolved_packages[@]}"
            ;;
        pacman)
            run_as_root pacman -S --noconfirm --needed "${resolved_packages[@]}"
            ;;
        zypper)
            run_as_root zypper install -y "${resolved_packages[@]}"
            ;;
        *)
            log_error "Unknown package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
}

# Remove packages
pkg_remove() {
    local packages=("$@")
    local resolved_packages=()

    for pkg in "${packages[@]}"; do
        resolved_packages+=("$(get_package_name "$pkg")")
    done

    log_info "Removing: ${resolved_packages[*]}"

    case "$PKG_MANAGER" in
        apt)
            run_as_root apt remove -y "${resolved_packages[@]}"
            ;;
        dnf)
            run_as_root dnf remove -y "${resolved_packages[@]}"
            ;;
        yum)
            run_as_root yum remove -y "${resolved_packages[@]}"
            ;;
        pacman)
            run_as_root pacman -R --noconfirm "${resolved_packages[@]}"
            ;;
        zypper)
            run_as_root zypper remove -y "${resolved_packages[@]}"
            ;;
        *)
            log_error "Unknown package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
}

# Search for packages
pkg_search() {
    local term="$1"

    case "$PKG_MANAGER" in
        apt)
            apt search "$term" 2>/dev/null
            ;;
        dnf|yum)
            "$PKG_MANAGER" search "$term" 2>/dev/null
            ;;
        pacman)
            pacman -Ss "$term" 2>/dev/null
            ;;
        zypper)
            zypper search "$term" 2>/dev/null
            ;;
        *)
            log_error "Unknown package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
}

# Check if a package is installed (native)
pkg_is_installed() {
    local pkg="$1"
    local resolved
    resolved=$(get_package_name "$pkg")

    case "$PKG_MANAGER" in
        apt)
            dpkg -l "$resolved" 2>/dev/null | grep -q '^ii'
            ;;
        dnf|yum)
            rpm -q "$resolved" &>/dev/null
            ;;
        pacman)
            pacman -Qi "$resolved" &>/dev/null
            ;;
        zypper)
            rpm -q "$resolved" &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# Upgrade all packages
pkg_upgrade() {
    log_info "Upgrading all packages..."

    case "$PKG_MANAGER" in
        apt)
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
        *)
            log_error "Unknown package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
}

# Clean package cache
pkg_clean() {
    log_info "Cleaning package cache..."

    case "$PKG_MANAGER" in
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
            run_as_root pacman -Sc --noconfirm
            ;;
        zypper)
            run_as_root zypper clean
            ;;
        *)
            log_error "Unknown package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
}

# ============================================================================
# FLATPAK FUNCTIONS
# ============================================================================

# Initialize Flatpak with Flathub
flatpak_init() {
    if [[ "$FLATPAK_AVAILABLE" -eq 0 ]]; then
        log_info "Installing Flatpak..."
        pkg_install flatpak

        if have_cmd flatpak; then
            FLATPAK_AVAILABLE=1
            FLATPAK_ENABLED=1
        else
            log_error "Failed to install Flatpak"
            return 1
        fi
    fi

    # Add Flathub if not configured
    if [[ "$FLATHUB_CONFIGURED" -eq 0 ]]; then
        log_info "Adding Flathub repository..."
        run_as_root flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        FLATHUB_CONFIGURED=1
        log_info "Flathub added. A logout/reboot may be required for full functionality."
    fi

    return 0
}

# Check if Flatpak app is installed
flatpak_is_installed() {
    local app_id="$1"

    [[ "$FLATPAK_AVAILABLE" -eq 0 ]] && return 1

    flatpak list --app 2>/dev/null | grep -q "$app_id"
}

# Install Flatpak app
flatpak_install() {
    local app="$1"
    local app_id

    if [[ "$FLATPAK_AVAILABLE" -eq 0 ]]; then
        log_error "Flatpak not available"
        return 1
    fi

    # Resolve app name to Flatpak ID
    if [[ -n "${FLATPAK_MAP[$app]:-}" ]]; then
        app_id="${FLATPAK_MAP[$app]}"
    else
        app_id="$app"
    fi

    log_info "Installing Flatpak: $app_id"

    # Ensure Flathub is set up
    flatpak_init

    flatpak install -y flathub "$app_id"
    return $?
}

# Remove Flatpak app
flatpak_remove() {
    local app="$1"
    local app_id

    [[ "$FLATPAK_AVAILABLE" -eq 0 ]] && return 1

    if [[ -n "${FLATPAK_MAP[$app]:-}" ]]; then
        app_id="${FLATPAK_MAP[$app]}"
    else
        app_id="$app"
    fi

    log_info "Removing Flatpak: $app_id"
    flatpak uninstall -y "$app_id"
}

# Update all Flatpak apps
flatpak_update() {
    [[ "$FLATPAK_AVAILABLE" -eq 0 ]] && return 1

    log_info "Updating Flatpak applications..."
    flatpak update -y
}

# List installed Flatpak apps
flatpak_list() {
    [[ "$FLATPAK_AVAILABLE" -eq 0 ]] && return 1

    flatpak list --app --columns=application,name,version
}

# Get Flatpak app ID for a generic name
get_flatpak_id() {
    local app="$1"
    echo "${FLATPAK_MAP[$app]:-}"
}

# Search Flatpak apps
flatpak_search() {
    local term="$1"

    [[ "$FLATPAK_AVAILABLE" -eq 0 ]] && return 1

    flatpak search "$term"
}

# ============================================================================
# SNAP FUNCTIONS
# ============================================================================

# Initialize Snap
snap_init() {
    if [[ "$SNAP_AVAILABLE" -eq 0 ]]; then
        log_info "Installing Snap..."
        pkg_install snapd

        # Enable and start snapd
        run_as_root systemctl enable --now snapd.socket
        run_as_root systemctl enable --now snapd

        # Create symlink for classic snaps
        if [[ ! -e /snap ]]; then
            run_as_root ln -s /var/lib/snapd/snap /snap
        fi

        if have_cmd snap; then
            SNAP_AVAILABLE=1
            log_info "Snap installed. A reboot may be required."
        else
            log_error "Failed to install Snap"
            return 1
        fi
    fi

    SNAP_ENABLED=1
    return 0
}

# Enable Snap support (user opt-in)
snap_enable() {
    if [[ "$SNAP_AVAILABLE" -eq 0 ]]; then
        snap_init
    fi
    SNAP_ENABLED=1
    log_info "Snap support enabled"
}

# Disable Snap support
snap_disable() {
    SNAP_ENABLED=0
    log_info "Snap support disabled"
}

# Check if Snap app is installed
snap_is_installed() {
    local app="$1"

    [[ "$SNAP_AVAILABLE" -eq 0 ]] && return 1

    snap list "$app" &>/dev/null
}

# Install Snap app
snap_install() {
    local app="$1"
    local snap_name
    local snap_flags=""

    if [[ "$SNAP_AVAILABLE" -eq 0 ]] || [[ "$SNAP_ENABLED" -eq 0 ]]; then
        log_error "Snap not available or not enabled"
        return 1
    fi

    # Resolve app name to Snap package
    if [[ -n "${SNAP_MAP[$app]:-}" ]]; then
        snap_name="${SNAP_MAP[$app]}"
    else
        snap_name="$app"
    fi

    log_info "Installing Snap: $snap_name"

    # Handle --classic flag
    if [[ "$snap_name" == *"--classic"* ]]; then
        run_as_root snap install $snap_name
    else
        run_as_root snap install "$snap_name"
    fi
}

# Remove Snap app
snap_remove() {
    local app="$1"

    [[ "$SNAP_AVAILABLE" -eq 0 ]] && return 1

    log_info "Removing Snap: $app"
    run_as_root snap remove "$app"
}

# Update all Snap apps
snap_update() {
    [[ "$SNAP_AVAILABLE" -eq 0 ]] && return 1

    log_info "Updating Snap applications..."
    run_as_root snap refresh
}

# List installed Snaps
snap_list() {
    [[ "$SNAP_AVAILABLE" -eq 0 ]] && return 1

    snap list
}

# ============================================================================
# UNIVERSAL INSTALL FUNCTIONS
# ============================================================================

# Smart install - tries native, then flatpak, then snap
# Arguments:
#   $1 - App name
#   $2 - Preferred method: "native", "flatpak", "snap", "auto" (default: auto)
smart_install() {
    local app="$1"
    local method="${2:-auto}"

    case "$method" in
        native)
            pkg_install "$app"
            ;;
        flatpak)
            flatpak_install "$app"
            ;;
        snap)
            snap_install "$app"
            ;;
        auto)
            # Try native first
            if pkg_install "$app" 2>/dev/null; then
                return 0
            fi

            # Try Flatpak if available
            if [[ "$FLATPAK_ENABLED" -eq 1 ]] && [[ -n "${FLATPAK_MAP[$app]:-}" ]]; then
                log_info "Native package not found, trying Flatpak..."
                if flatpak_install "$app"; then
                    return 0
                fi
            fi

            # Try Snap if enabled
            if [[ "$SNAP_ENABLED" -eq 1 ]] && [[ -n "${SNAP_MAP[$app]:-}" ]]; then
                log_info "Trying Snap..."
                if snap_install "$app"; then
                    return 0
                fi
            fi

            log_error "Failed to install $app via any method"
            return 1
            ;;
    esac
}

# Check if app is installed (any method)
is_installed() {
    local app="$1"

    # Check native
    if pkg_is_installed "$app"; then
        return 0
    fi

    # Check Flatpak
    if [[ "$FLATPAK_AVAILABLE" -eq 1 ]]; then
        local flatpak_id="${FLATPAK_MAP[$app]:-$app}"
        if flatpak_is_installed "$flatpak_id"; then
            return 0
        fi
    fi

    # Check Snap
    if [[ "$SNAP_AVAILABLE" -eq 1 ]]; then
        if snap_is_installed "$app"; then
            return 0
        fi
    fi

    # Check if command exists
    if have_cmd "$app"; then
        return 0
    fi

    return 1
}

# Get installation status string
get_install_status() {
    local app="$1"

    if pkg_is_installed "$app"; then
        echo "native"
        return 0
    fi

    if [[ "$FLATPAK_AVAILABLE" -eq 1 ]]; then
        local flatpak_id="${FLATPAK_MAP[$app]:-}"
        if [[ -n "$flatpak_id" ]] && flatpak_is_installed "$flatpak_id"; then
            echo "flatpak"
            return 0
        fi
    fi

    if [[ "$SNAP_AVAILABLE" -eq 1 ]]; then
        if snap_is_installed "$app"; then
            echo "snap"
            return 0
        fi
    fi

    echo "not installed"
    return 1
}

# ============================================================================
# BATCH OPERATIONS
# ============================================================================

# Install multiple packages with progress
pkg_install_batch() {
    local packages=("$@")
    local total=${#packages[@]}
    local current=0
    local failed=()
    local succeeded=()

    for pkg in "${packages[@]}"; do
        ((current++))
        log_info "[$current/$total] Installing $pkg..."

        if pkg_install "$pkg" 2>/dev/null; then
            succeeded+=("$pkg")
        else
            failed+=("$pkg")
            log_warn "Failed to install: $pkg"
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_warn "Failed packages (${#failed[@]}): ${failed[*]}"
    fi

    if [[ ${#succeeded[@]} -gt 0 ]]; then
        log_info "Successfully installed (${#succeeded[@]}): ${succeeded[*]}"
    fi

    [[ ${#failed[@]} -eq 0 ]]
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Add a custom package mapping
add_package_mapping() {
    local generic="$1"
    local mapping="$2"
    PACKAGE_MAP["$generic"]="$mapping"
}

# Add a custom Flatpak mapping
add_flatpak_mapping() {
    local app="$1"
    local app_id="$2"
    FLATPAK_MAP["$app"]="$app_id"
}

# Check if essential tools are available
check_package_tools() {
    case "$PKG_MANAGER" in
        apt)
            have_cmd apt && have_cmd dpkg
            ;;
        dnf)
            have_cmd dnf && have_cmd rpm
            ;;
        yum)
            have_cmd yum && have_cmd rpm
            ;;
        pacman)
            have_cmd pacman
            ;;
        zypper)
            have_cmd zypper && have_cmd rpm
            ;;
        *)
            return 1
            ;;
    esac
}

# Print package system info
print_pkg_info() {
    echo "Package Manager: $PKG_MANAGER"
    echo "Flatpak: $([ "$FLATPAK_AVAILABLE" -eq 1 ] && echo "Available" || echo "Not available")"
    echo "  Enabled: $([ "$FLATPAK_ENABLED" -eq 1 ] && echo "Yes" || echo "No")"
    echo "  Flathub: $([ "$FLATHUB_CONFIGURED" -eq 1 ] && echo "Configured" || echo "Not configured")"
    echo "Snap: $([ "$SNAP_AVAILABLE" -eq 1 ] && echo "Available" || echo "Not available")"
    echo "  Enabled: $([ "$SNAP_ENABLED" -eq 1 ] && echo "Yes" || echo "No")"
}

# Get available install methods for an app
get_install_methods() {
    local app="$1"
    local methods=()

    # Always can try native
    methods+=("native")

    # Check Flatpak
    if [[ "$FLATPAK_AVAILABLE" -eq 1 ]] && [[ -n "${FLATPAK_MAP[$app]:-}" ]]; then
        methods+=("flatpak")
    fi

    # Check Snap
    if [[ "$SNAP_AVAILABLE" -eq 1 ]] && [[ -n "${SNAP_MAP[$app]:-}" ]]; then
        methods+=("snap")
    fi

    echo "${methods[*]}"
}
