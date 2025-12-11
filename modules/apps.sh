#!/usr/bin/env bash
#
# apps.sh - Application Installer Module for Ultimate Linux Suite
#
# Provides comprehensive application installation with queue management,
# per-OS package mapping, Flatpak support, and preset bundles.
#

# Prevent multiple sourcing
[[ -n "${_MODULE_APPS_LOADED:-}" ]] && return 0
readonly _MODULE_APPS_LOADED=1

# ============================================================================
# GLOBAL VARIABLES
# ============================================================================

# Installation queue (array of app identifiers)
declare -ga INSTALL_QUEUE=()

# Failed installations
declare -ga INSTALL_FAILED=()

# Successful installations
declare -ga INSTALL_SUCCESS=()

# ============================================================================
# APPLICATION DATABASE
# ============================================================================

# Application definitions
# Format: APP_DB[app_id]="name|category|description|prefer_method|post_install"
# prefer_method: native, flatpak, snap, auto
# post_install: comma-separated commands or group additions

declare -gA APP_DB=(
    # -------------------------------------------------------------------------
    # BROWSERS
    # -------------------------------------------------------------------------
    ["firefox"]="Firefox|browsers|Fast, private, free web browser|native|"
    ["firefox-esr"]="Firefox ESR|browsers|Extended Support Release of Firefox|native|"
    ["chromium"]="Chromium|browsers|Open-source web browser|native|"
    ["chrome"]="Google Chrome|browsers|Web browser by Google|flatpak|"
    ["brave"]="Brave|browsers|Privacy-focused browser with ad blocking|flatpak|"
    ["vivaldi"]="Vivaldi|browsers|Customizable browser for power users|flatpak|"
    ["opera"]="Opera|browsers|Feature-rich web browser|flatpak|"
    ["ungoogled-chromium"]="Ungoogled Chromium|browsers|Chromium without Google services|flatpak|"
    ["librewolf"]="LibreWolf|browsers|Privacy-focused Firefox fork|flatpak|"
    ["tor-browser"]="Tor Browser|browsers|Anonymous browsing via Tor network|flatpak|"

    # -------------------------------------------------------------------------
    # DEVELOPMENT
    # -------------------------------------------------------------------------
    ["vscode"]="VS Code|development|Visual Studio Code editor|flatpak|"
    ["vscodium"]="VSCodium|development|VS Code without Microsoft telemetry|flatpak|"
    ["neovim"]="Neovim|development|Hyperextensible Vim-based editor|native|"
    ["vim"]="Vim|development|Improved Vi text editor|native|"
    ["emacs"]="Emacs|development|Extensible text editor|native|"
    ["sublime-text"]="Sublime Text|development|Sophisticated text editor|flatpak|"
    ["git"]="Git|development|Distributed version control system|native|"
    ["git-lfs"]="Git LFS|development|Git extension for large files|native|"
    ["gittyup"]="Gittyup|development|Graphical Git client|flatpak|"
    ["gitkraken"]="GitKraken|development|Git GUI client|flatpak|"
    ["docker"]="Docker|development|Container platform|native|add_group:docker"
    ["docker-compose"]="Docker Compose|development|Multi-container Docker apps|native|"
    ["podman"]="Podman|development|Daemonless container engine|native|"
    ["nodejs"]="Node.js|development|JavaScript runtime|native|"
    ["npm"]="npm|development|Node.js package manager|native|"
    ["python3"]="Python 3|development|Python programming language|native|"
    ["python3-pip"]="pip|development|Python package installer|native|"
    ["python3-venv"]="Python venv|development|Python virtual environments|native|"
    ["golang"]="Go|development|Go programming language|native|"
    ["rust"]="Rust|development|Rust programming language|native|"
    ["cargo"]="Cargo|development|Rust package manager|native|"
    ["build-essential"]="Build Essential|development|C/C++ compilation tools|native|"
    ["cmake"]="CMake|development|Cross-platform build system|native|"
    ["meson"]="Meson|development|Build system|native|"
    ["gdb"]="GDB|development|GNU Debugger|native|"
    ["valgrind"]="Valgrind|development|Memory debugging tool|native|"
    ["strace"]="strace|development|System call tracer|native|"
    ["postman"]="Postman|development|API development platform|flatpak|"
    ["dbeaver"]="DBeaver|development|Universal database tool|flatpak|"
    ["insomnia"]="Insomnia|development|REST/GraphQL API client|flatpak|"

    # -------------------------------------------------------------------------
    # GAMING
    # -------------------------------------------------------------------------
    ["steam"]="Steam|gaming|Game distribution platform|flatpak|add_group:input"
    ["lutris"]="Lutris|gaming|Open gaming platform|flatpak|"
    ["heroic"]="Heroic Launcher|gaming|Epic Games & GOG launcher|flatpak|"
    ["bottles"]="Bottles|gaming|Run Windows software easily|flatpak|"
    ["wine"]="Wine|gaming|Windows compatibility layer|native|"
    ["wine-staging"]="Wine Staging|gaming|Wine with extra patches|native|"
    ["gamemode"]="GameMode|gaming|Optimize system for gaming|native|"
    ["mangohud"]="MangoHud|gaming|Vulkan/OpenGL overlay|native|"
    ["goverlay"]="GOverlay|gaming|MangoHud configuration GUI|native|"
    ["protonup-qt"]="ProtonUp-Qt|gaming|Proton version manager|flatpak|"
    ["gamescope"]="Gamescope|gaming|SteamOS session compositor|native|"
    ["antimicrox"]="AntiMicroX|gaming|Controller to keyboard mapper|native|"

    # -------------------------------------------------------------------------
    # SYSTEM UTILITIES
    # -------------------------------------------------------------------------
    ["htop"]="htop|utilities|Interactive process viewer|native|"
    ["btop"]="btop|utilities|Resource monitor|native|"
    ["neofetch"]="Neofetch|utilities|System info tool|native|"
    ["fastfetch"]="Fastfetch|utilities|Fast system info tool|native|"
    ["tmux"]="tmux|utilities|Terminal multiplexer|native|"
    ["screen"]="GNU Screen|utilities|Terminal multiplexer|native|"
    ["mc"]="Midnight Commander|utilities|File manager|native|"
    ["tree"]="tree|utilities|Directory listing|native|"
    ["ncdu"]="ncdu|utilities|NCurses disk usage|native|"
    ["gparted"]="GParted|utilities|Partition editor|native|"
    ["gnome-disks"]="GNOME Disks|utilities|Disk utility|native|"
    ["timeshift"]="Timeshift|utilities|System restore tool|native|"
    ["bleachbit"]="BleachBit|utilities|System cleaner|native|"
    ["stacer"]="Stacer|utilities|System optimizer|native|"
    ["flatseal"]="Flatseal|utilities|Flatpak permission manager|flatpak|"
    ["dconf-editor"]="dconf Editor|utilities|GNOME settings editor|native|"
    ["fzf"]="fzf|utilities|Fuzzy finder|native|"
    ["ripgrep"]="ripgrep|utilities|Fast grep alternative|native|"
    ["fd-find"]="fd|utilities|Fast find alternative|native|"
    ["bat"]="bat|utilities|cat with syntax highlighting|native|"
    ["exa"]="exa|utilities|Modern ls replacement|native|"
    ["zoxide"]="zoxide|utilities|Smarter cd command|native|"
    ["jq"]="jq|utilities|JSON processor|native|"

    # -------------------------------------------------------------------------
    # MEDIA
    # -------------------------------------------------------------------------
    ["vlc"]="VLC|media|Multimedia player|native|"
    ["mpv"]="mpv|media|Media player|native|"
    ["ffmpeg"]="FFmpeg|media|Multimedia framework|native|"
    ["audacity"]="Audacity|media|Audio editor|flatpak|"
    ["obs-studio"]="OBS Studio|media|Streaming/recording software|flatpak|"
    ["kdenlive"]="Kdenlive|media|Video editor|flatpak|"
    ["shotcut"]="Shotcut|media|Video editor|flatpak|"
    ["openshot"]="OpenShot|media|Video editor|flatpak|"
    ["handbrake"]="HandBrake|media|Video transcoder|flatpak|"
    ["pitivi"]="Pitivi|media|Simple video editor|flatpak|"
    ["rhythmbox"]="Rhythmbox|media|Music player|native|"
    ["lollypop"]="Lollypop|media|Music player|flatpak|"
    ["spotify"]="Spotify|media|Music streaming|flatpak|"
    ["clementine"]="Clementine|media|Music player|native|"

    # -------------------------------------------------------------------------
    # GRAPHICS & DESIGN
    # -------------------------------------------------------------------------
    ["gimp"]="GIMP|graphics|Image editor|flatpak|"
    ["inkscape"]="Inkscape|graphics|Vector graphics editor|flatpak|"
    ["krita"]="Krita|graphics|Digital painting|flatpak|"
    ["blender"]="Blender|graphics|3D creation suite|flatpak|"
    ["darktable"]="darktable|graphics|Photography workflow|flatpak|"
    ["rawtherapee"]="RawTherapee|graphics|Raw photo processor|flatpak|"
    ["imagemagick"]="ImageMagick|graphics|Image manipulation|native|"
    ["pinta"]="Pinta|graphics|Simple image editor|flatpak|"
    ["drawio"]="Draw.io|graphics|Diagramming tool|flatpak|"

    # -------------------------------------------------------------------------
    # OFFICE & PRODUCTIVITY
    # -------------------------------------------------------------------------
    ["libreoffice"]="LibreOffice|office|Office suite|native|"
    ["onlyoffice"]="OnlyOffice|office|Office suite|flatpak|"
    ["thunderbird"]="Thunderbird|office|Email client|native|"
    ["evince"]="Evince|office|Document viewer|native|"
    ["okular"]="Okular|office|Document viewer|native|"
    ["calibre"]="Calibre|office|E-book manager|flatpak|"
    ["obsidian"]="Obsidian|office|Knowledge base|flatpak|"
    ["joplin"]="Joplin|office|Note-taking app|flatpak|"
    ["standard-notes"]="Standard Notes|office|Encrypted notes|flatpak|"
    ["logseq"]="Logseq|office|Knowledge management|flatpak|"
    ["notion"]="Notion|office|All-in-one workspace|flatpak|"
    ["zotero"]="Zotero|office|Research assistant|flatpak|"

    # -------------------------------------------------------------------------
    # COMMUNICATION
    # -------------------------------------------------------------------------
    ["discord"]="Discord|communication|Voice & text chat|flatpak|"
    ["slack"]="Slack|communication|Team collaboration|flatpak|"
    ["zoom"]="Zoom|communication|Video conferencing|flatpak|"
    ["telegram"]="Telegram|communication|Messaging app|flatpak|"
    ["signal"]="Signal|communication|Private messenger|flatpak|"
    ["element"]="Element|communication|Matrix client|flatpak|"
    ["teams"]="Microsoft Teams|communication|Team collaboration|flatpak|"
    ["skype"]="Skype|communication|Video calls|flatpak|"
    ["hexchat"]="HexChat|communication|IRC client|native|"
    ["pidgin"]="Pidgin|communication|Multi-protocol IM|native|"

    # -------------------------------------------------------------------------
    # VIRTUALIZATION
    # -------------------------------------------------------------------------
    ["virtualbox"]="VirtualBox|virtualization|Desktop virtualization|native|add_group:vboxusers"
    ["qemu"]="QEMU|virtualization|Machine emulator|native|add_group:libvirt"
    ["virt-manager"]="Virt Manager|virtualization|VM management|native|add_group:libvirt"
    ["libvirt"]="libvirt|virtualization|Virtualization API|native|"
    ["gnome-boxes"]="GNOME Boxes|virtualization|Simple VM manager|flatpak|"

    # -------------------------------------------------------------------------
    # NETWORK TOOLS
    # -------------------------------------------------------------------------
    ["net-tools"]="net-tools|network|Network utilities|native|"
    ["nmap"]="Nmap|network|Network scanner|native|"
    ["wireshark"]="Wireshark|network|Network analyzer|native|add_group:wireshark"
    ["tcpdump"]="tcpdump|network|Packet analyzer|native|"
    ["curl"]="cURL|network|Data transfer tool|native|"
    ["wget"]="wget|network|File retriever|native|"
    ["openssh-client"]="OpenSSH Client|network|SSH client|native|"
    ["openssh-server"]="OpenSSH Server|network|SSH server|native|"
    ["wireguard"]="WireGuard|network|VPN protocol|native|"
    ["tailscale"]="Tailscale|network|Mesh VPN|native|"
    ["rclone"]="Rclone|network|Cloud storage sync|native|"
    ["syncthing"]="Syncthing|network|File synchronization|native|"
    ["filezilla"]="FileZilla|network|FTP client|native|"
    ["transmission"]="Transmission|network|BitTorrent client|native|"
    ["qbittorrent"]="qBittorrent|network|BitTorrent client|native|"

    # -------------------------------------------------------------------------
    # SECURITY
    # -------------------------------------------------------------------------
    ["clamav"]="ClamAV|security|Antivirus engine|native|"
    ["ufw"]="UFW|security|Firewall|native|"
    ["fail2ban"]="fail2ban|security|Intrusion prevention|native|"
    ["keepassxc"]="KeePassXC|security|Password manager|flatpak|"
    ["bitwarden"]="Bitwarden|security|Password manager|flatpak|"
    ["veracrypt"]="VeraCrypt|security|Disk encryption|native|"
    ["seahorse"]="Seahorse|security|GNOME keyring manager|native|"

    # -------------------------------------------------------------------------
    # ARCHIVE & COMPRESSION
    # -------------------------------------------------------------------------
    ["zip"]="zip|archive|ZIP compression|native|"
    ["unzip"]="unzip|archive|ZIP extraction|native|"
    ["p7zip"]="7-Zip|archive|7z compression|native|"
    ["unrar"]="unrar|archive|RAR extraction|native|"
    ["file-roller"]="File Roller|archive|Archive manager|native|"
    ["ark"]="Ark|archive|KDE archive manager|native|"

    # -------------------------------------------------------------------------
    # SHELL & TERMINAL
    # -------------------------------------------------------------------------
    ["zsh"]="Zsh|shell|Z shell|native|"
    ["fish"]="Fish|shell|Friendly shell|native|"
    ["bash-completion"]="Bash Completion|shell|Tab completion|native|"
    ["alacritty"]="Alacritty|shell|GPU-accelerated terminal|native|"
    ["kitty"]="Kitty|shell|GPU-based terminal|native|"
    ["tilix"]="Tilix|shell|Tiling terminal|native|"
    ["terminator"]="Terminator|shell|Terminal emulator|native|"
)

# ============================================================================
# CATEGORY DEFINITIONS
# ============================================================================

# Categories with display names and descriptions
declare -gA APP_CATEGORIES=(
    ["browsers"]="Web Browsers|Browse the internet"
    ["development"]="Development Tools|Programming and development"
    ["gaming"]="Gaming|Games and gaming platforms"
    ["utilities"]="System Utilities|System tools and utilities"
    ["media"]="Media|Audio and video applications"
    ["graphics"]="Graphics & Design|Image and graphic editing"
    ["office"]="Office & Productivity|Documents and productivity"
    ["communication"]="Communication|Chat and messaging"
    ["virtualization"]="Virtualization|Virtual machines and containers"
    ["network"]="Network Tools|Network utilities"
    ["security"]="Security|Security tools"
    ["archive"]="Archive & Compression|File compression tools"
    ["shell"]="Shell & Terminal|Shell and terminal tools"
)

# ============================================================================
# PRESET DEFINITIONS
# ============================================================================

# Preset configurations
declare -gA APP_PRESETS=(
    ["gaming"]="steam lutris heroic bottles wine gamemode mangohud protonup-qt discord"
    ["developer"]="git neovim vscode docker docker-compose nodejs python3 python3-pip build-essential cmake htop tmux jq curl wget"
    ["creator"]="gimp inkscape krita blender kdenlive obs-studio audacity handbrake darktable"
    ["minimal"]="vim htop curl wget git neofetch tmux zip unzip"
    ["office"]="libreoffice thunderbird evince calibre"
    ["security"]="clamav ufw fail2ban keepassxc wireshark nmap"
    ["communication"]="discord telegram signal element slack"
    ["media"]="vlc mpv ffmpeg audacity spotify"
)

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Initialize apps module
module_apps_init() {
    log_debug "Applications module initialized"

    # Initialize package system
    if declare -f pkg_init &>/dev/null; then
        pkg_init
    fi

    # Load presets from config files
    _load_preset_files

    return 0
}

# Load presets from config files
_load_preset_files() {
    local config_dir="${SUITE_DIR:-$(dirname "$(dirname "${BASH_SOURCE[0]}")")}/configs/app_presets"

    if [[ ! -d "$config_dir" ]]; then
        log_debug "Preset config directory not found: $config_dir"
        return 0
    fi

    local conf_file
    for conf_file in "$config_dir"/*.conf; do
        [[ -f "$conf_file" ]] || continue
        _parse_preset_file "$conf_file"
    done

    log_debug "Preset files loaded from $config_dir"
}

# Parse a preset config file
_parse_preset_file() {
    local file="$1"
    local preset_name=""
    local packages=""
    local in_packages=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Remove leading/trailing whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        # Parse section headers
        if [[ "$line" =~ ^\[([^\]]+)\]$ ]]; then
            local section="${BASH_REMATCH[1]}"
            if [[ "$section" == "packages" ]]; then
                in_packages=1
            elif [[ "$section" == "preset" ]]; then
                in_packages=0
            else
                in_packages=0
            fi
            continue
        fi

        # Parse preset name
        if [[ "$line" =~ ^name=(.+)$ ]]; then
            preset_name=$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
            continue
        fi

        # Parse packages
        if [[ "$in_packages" -eq 1 ]] && [[ "$line" =~ ^([^=]+)= ]]; then
            local pkg_name="${BASH_REMATCH[1]}"
            packages+=" $pkg_name"
        fi
    done < "$file"

    # Store parsed preset if valid
    if [[ -n "$preset_name" && -n "$packages" ]]; then
        packages="${packages# }"  # Remove leading space
        APP_PRESETS["$preset_name"]="$packages"
        log_debug "Loaded preset: $preset_name with packages: $packages"
    fi
}

# ============================================================================
# APPLICATION INFO FUNCTIONS
# ============================================================================

# Get app info field
# Arguments:
#   $1 - App ID
#   $2 - Field number (1=name, 2=category, 3=desc, 4=method, 5=post)
_get_app_field() {
    local app_id="$1"
    local field="$2"
    local info="${APP_DB[$app_id]:-}"

    [[ -z "$info" ]] && return 1

    echo "$info" | cut -d'|' -f"$field"
}

# Get app display name
get_app_name() {
    _get_app_field "$1" 1
}

# Get app category
get_app_category() {
    _get_app_field "$1" 2
}

# Get app description
get_app_description() {
    _get_app_field "$1" 3
}

# Get preferred install method
get_app_method() {
    local method
    method=$(_get_app_field "$1" 4)
    echo "${method:-native}"
}

# Get post-install commands
get_app_post_install() {
    _get_app_field "$1" 5
}

# Check if app exists in database
app_exists() {
    local app_id="$1"
    [[ -n "${APP_DB[$app_id]:-}" ]]
}

# List all apps in a category
list_apps_in_category() {
    local category="$1"
    local apps=()

    for app_id in "${!APP_DB[@]}"; do
        if [[ "$(get_app_category "$app_id")" == "$category" ]]; then
            apps+=("$app_id")
        fi
    done

    # Sort and output
    printf '%s\n' "${apps[@]}" | sort
}

# List all categories
list_categories() {
    printf '%s\n' "${!APP_CATEGORIES[@]}" | sort
}

# Get category display name
get_category_name() {
    local cat="$1"
    echo "${APP_CATEGORIES[$cat]:-$cat}" | cut -d'|' -f1
}

# Get category description
get_category_description() {
    local cat="$1"
    echo "${APP_CATEGORIES[$cat]:-}" | cut -d'|' -f2
}

# ============================================================================
# INSTALLATION STATUS
# ============================================================================

# Check if app is installed
is_app_installed() {
    local app_id="$1"

    # Use universal check from pkg.sh
    if declare -f is_installed &>/dev/null; then
        is_installed "$app_id"
        return $?
    fi

    # Fallback
    pkg_is_installed "$app_id"
}

# Get detailed install status
get_app_status() {
    local app_id="$1"

    if declare -f get_install_status &>/dev/null; then
        get_install_status "$app_id"
    elif is_app_installed "$app_id"; then
        echo "installed"
    else
        echo "not installed"
    fi
}

# Get status display string (for menus)
get_app_status_display() {
    local app_id="$1"
    local status
    status=$(get_app_status "$app_id")

    case "$status" in
        native)     echo "[native]" ;;
        flatpak)    echo "[flatpak]" ;;
        snap)       echo "[snap]" ;;
        installed)  echo "[installed]" ;;
        *)          echo "" ;;
    esac
}

# ============================================================================
# QUEUE MANAGEMENT
# ============================================================================

# Add app to install queue
queue_add() {
    local app_id="$1"

    # Validate app exists
    if ! app_exists "$app_id"; then
        log_warn "Unknown app: $app_id"
        return 1
    fi

    # Check if already in queue
    if queue_contains "$app_id"; then
        log_debug "App already in queue: $app_id"
        return 0
    fi

    # Check if already installed
    if is_app_installed "$app_id"; then
        log_debug "App already installed: $app_id"
        return 0
    fi

    INSTALL_QUEUE+=("$app_id")
    log_debug "Added to queue: $app_id"
    return 0
}

# Remove app from queue
queue_remove() {
    local app_id="$1"
    local new_queue=()

    for item in "${INSTALL_QUEUE[@]}"; do
        if [[ "$item" != "$app_id" ]]; then
            new_queue+=("$item")
        fi
    done

    INSTALL_QUEUE=("${new_queue[@]}")
    log_debug "Removed from queue: $app_id"
}

# Check if app is in queue
queue_contains() {
    local app_id="$1"

    for item in "${INSTALL_QUEUE[@]}"; do
        [[ "$item" == "$app_id" ]] && return 0
    done

    return 1
}

# Clear the queue
queue_clear() {
    INSTALL_QUEUE=()
    log_debug "Install queue cleared"
}

# Get queue size
queue_size() {
    echo "${#INSTALL_QUEUE[@]}"
}

# Get queue contents
queue_list() {
    printf '%s\n' "${INSTALL_QUEUE[@]}"
}

# Add multiple apps to queue
queue_add_multiple() {
    local apps=("$@")

    for app in "${apps[@]}"; do
        queue_add "$app"
    done
}

# Load preset into queue
queue_load_preset() {
    local preset="$1"

    if [[ -z "${APP_PRESETS[$preset]:-}" ]]; then
        log_error "Unknown preset: $preset"
        return 1
    fi

    local apps
    # shellcheck disable=SC2206
    apps=(${APP_PRESETS[$preset]})

    log_info "Loading preset '$preset' with ${#apps[@]} apps"

    for app in "${apps[@]}"; do
        queue_add "$app"
    done

    return 0
}

# ============================================================================
# INSTALLATION FUNCTIONS
# ============================================================================

# Install a single app
install_app() {
    local app_id="$1"
    local method="${2:-}"  # Optional: override method

    if ! app_exists "$app_id"; then
        log_error "Unknown app: $app_id"
        return 1
    fi

    # Skip if already installed
    if is_app_installed "$app_id"; then
        log_info "Already installed: $(get_app_name "$app_id")"
        return 0
    fi

    local app_name
    app_name=$(get_app_name "$app_id")
    method="${method:-$(get_app_method "$app_id")}"

    log_info "Installing $app_name via $method..."

    local result=0

    case "$method" in
        flatpak)
            if [[ "$FLATPAK_AVAILABLE" -eq 1 ]]; then
                flatpak_install "$app_id"
                result=$?
            else
                log_warn "Flatpak not available, trying native..."
                pkg_install "$app_id"
                result=$?
            fi
            ;;
        snap)
            if [[ "$SNAP_ENABLED" -eq 1 ]]; then
                snap_install "$app_id"
                result=$?
            else
                log_warn "Snap not enabled, trying native..."
                pkg_install "$app_id"
                result=$?
            fi
            ;;
        native)
            pkg_install "$app_id"
            result=$?
            ;;
        auto)
            if declare -f smart_install &>/dev/null; then
                smart_install "$app_id"
                result=$?
            else
                pkg_install "$app_id"
                result=$?
            fi
            ;;
        *)
            pkg_install "$app_id"
            result=$?
            ;;
    esac

    # Run post-install if successful
    if [[ $result -eq 0 ]]; then
        _run_post_install "$app_id"
        log_info "Successfully installed: $app_name"
    else
        log_error "Failed to install: $app_name"
    fi

    return $result
}

# Run post-install commands
_run_post_install() {
    local app_id="$1"
    local post_install
    post_install=$(get_app_post_install "$app_id")

    [[ -z "$post_install" ]] && return 0

    log_debug "Running post-install for $app_id: $post_install"

    # Parse comma-separated commands
    IFS=',' read -ra commands <<< "$post_install"

    for cmd in "${commands[@]}"; do
        cmd="${cmd#"${cmd%%[![:space:]]*}"}"  # Trim leading whitespace

        # Handle group additions
        if [[ "$cmd" =~ ^add_group:(.+)$ ]]; then
            local group="${BASH_REMATCH[1]}"
            _add_user_to_group "$group"
            continue
        fi

        # Handle enable service
        if [[ "$cmd" =~ ^enable_service:(.+)$ ]]; then
            local service="${BASH_REMATCH[1]}"
            run_as_root systemctl enable --now "$service" 2>/dev/null || true
            continue
        fi

        # Run as command
        eval "$cmd" 2>/dev/null || log_warn "Post-install command failed: $cmd"
    done
}

# Add current user to a group
_add_user_to_group() {
    local group="$1"
    local user="${SUDO_USER:-$USER}"

    log_info "Adding user $user to group $group..."

    # Create group if needed
    if ! getent group "$group" &>/dev/null; then
        run_as_root groupadd "$group" 2>/dev/null || true
    fi

    # Add user to group
    run_as_root usermod -aG "$group" "$user"

    log_info "User $user added to $group. You may need to log out and back in."
}

# ============================================================================
# BATCH INSTALLATION
# ============================================================================

# Install all apps in queue
install_queue() {
    local total
    total=$(queue_size)

    if [[ "$total" -eq 0 ]]; then
        log_warn "Install queue is empty"
        return 0
    fi

    log_info "Installing $total applications..."

    # Reset result arrays
    INSTALL_FAILED=()
    INSTALL_SUCCESS=()

    local current=0
    local app_id

    # Ensure package indexes are updated
    log_info "Updating package indexes..."
    pkg_update_indexes

    # Ensure Flatpak is ready if needed
    local needs_flatpak=0
    for app_id in "${INSTALL_QUEUE[@]}"; do
        if [[ "$(get_app_method "$app_id")" == "flatpak" ]]; then
            needs_flatpak=1
            break
        fi
    done

    if [[ "$needs_flatpak" -eq 1 ]] && [[ "$FLATPAK_AVAILABLE" -eq 1 ]]; then
        log_info "Initializing Flatpak..."
        flatpak_init
    fi

    # Install each app
    for app_id in "${INSTALL_QUEUE[@]}"; do
        ((current++))
        local app_name
        app_name=$(get_app_name "$app_id")

        log_info "[$current/$total] Installing $app_name..."

        if install_app "$app_id"; then
            INSTALL_SUCCESS+=("$app_id")
        else
            INSTALL_FAILED+=("$app_id")
        fi
    done

    # Clear queue
    queue_clear

    # Report results
    log_info "Installation complete:"
    log_info "  Successful: ${#INSTALL_SUCCESS[@]}"
    log_info "  Failed: ${#INSTALL_FAILED[@]}"

    if [[ ${#INSTALL_FAILED[@]} -gt 0 ]]; then
        log_warn "Failed apps: ${INSTALL_FAILED[*]}"
        return 1
    fi

    return 0
}

# Get installation summary
get_install_summary() {
    echo "Successful: ${#INSTALL_SUCCESS[@]}"
    echo "Failed: ${#INSTALL_FAILED[@]}"

    if [[ ${#INSTALL_SUCCESS[@]} -gt 0 ]]; then
        echo ""
        echo "Installed:"
        for app in "${INSTALL_SUCCESS[@]}"; do
            echo "  - $(get_app_name "$app")"
        done
    fi

    if [[ ${#INSTALL_FAILED[@]} -gt 0 ]]; then
        echo ""
        echo "Failed:"
        for app in "${INSTALL_FAILED[@]}"; do
            echo "  - $(get_app_name "$app")"
        done
    fi
}

# ============================================================================
# PRESET FUNCTIONS
# ============================================================================

# List available presets
list_presets() {
    printf '%s\n' "${!APP_PRESETS[@]}" | sort
}

# Get preset packages
get_preset_packages() {
    local preset="$1"
    echo "${APP_PRESETS[$preset]:-}"
}

# Get preset app count
get_preset_count() {
    local preset="$1"
    local packages="${APP_PRESETS[$preset]:-}"

    if [[ -z "$packages" ]]; then
        echo 0
        return
    fi

    # shellcheck disable=SC2086
    set -- $packages
    echo $#
}

# Install a preset directly
install_preset() {
    local preset="$1"

    queue_clear
    queue_load_preset "$preset"
    install_queue
}

# ============================================================================
# HARDWARE-BASED RECOMMENDATIONS
# ============================================================================

# Get recommended preset based on hardware
get_recommended_preset() {
    # Check for gaming capability
    if [[ "$GPU_VENDOR" == "nvidia" ]] || [[ "$GPU_VENDOR" == "amd" ]]; then
        if [[ "${TOTAL_RAM_MB:-0}" -ge 8192 ]]; then
            echo "gaming"
            return
        fi
    fi

    # Check for workstation (many cores)
    if [[ "${CPU_CORES:-1}" -ge 8 ]] && [[ "${TOTAL_RAM_MB:-0}" -ge 16384 ]]; then
        echo "developer"
        return
    fi

    # Low-spec system
    if [[ "${TOTAL_RAM_MB:-0}" -lt 4096 ]]; then
        echo "minimal"
        return
    fi

    # Default
    echo "office"
}

# Get recommended apps for system
get_recommended_apps() {
    local apps=()

    # Always recommend basics
    apps+=(htop git curl wget)

    # Based on GPU
    case "${GPU_VENDOR:-}" in
        nvidia|amd)
            apps+=(steam gamemode mangohud)
            ;;
    esac

    # Based on RAM
    if [[ "${TOTAL_RAM_MB:-0}" -ge 8192 ]]; then
        apps+=(vscode docker)
    fi

    # Based on form factor
    if [[ "${FORM_FACTOR:-}" == "laptop" ]]; then
        apps+=(timeshift)
    fi

    printf '%s\n' "${apps[@]}"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Search apps by name/description
search_apps() {
    local term="$1"
    local term_lower
    term_lower=$(echo "$term" | tr '[:upper:]' '[:lower:]')

    for app_id in "${!APP_DB[@]}"; do
        local name desc
        name=$(get_app_name "$app_id")
        desc=$(get_app_description "$app_id")

        local name_lower desc_lower
        name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
        desc_lower=$(echo "$desc" | tr '[:upper:]' '[:lower:]')

        if [[ "$app_id" == *"$term_lower"* ]] || \
           [[ "$name_lower" == *"$term_lower"* ]] || \
           [[ "$desc_lower" == *"$term_lower"* ]]; then
            echo "$app_id"
        fi
    done | sort
}

# Get app info as formatted string
get_app_info() {
    local app_id="$1"

    if ! app_exists "$app_id"; then
        echo "Unknown app: $app_id"
        return 1
    fi

    local name desc cat method status
    name=$(get_app_name "$app_id")
    desc=$(get_app_description "$app_id")
    cat=$(get_app_category "$app_id")
    method=$(get_app_method "$app_id")
    status=$(get_app_status "$app_id")

    echo "App: $name"
    echo "ID: $app_id"
    echo "Category: $cat"
    echo "Description: $desc"
    echo "Preferred Method: $method"
    echo "Status: $status"
}

# Count apps per category
count_apps_in_category() {
    local category="$1"
    local count=0

    for app_id in "${!APP_DB[@]}"; do
        if [[ "$(get_app_category "$app_id")" == "$category" ]]; then
            ((count++))
        fi
    done

    echo "$count"
}

# Count total apps
count_total_apps() {
    echo "${#APP_DB[@]}"
}
