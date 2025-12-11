# Application Management Guide

Ultimate Linux Suite provides a comprehensive application installer with support for native packages, Flatpak, and Snap.

## Overview

The application management system supports:
- Native package installation (apt, dnf, pacman, zypper)
- Flatpak applications
- Snap packages
- Application presets for quick setup
- Queue-based batch installation

## Installation Methods

### Native Packages
Traditional distribution packages installed via the system package manager:
- **Debian/Ubuntu**: apt
- **Fedora/RHEL**: dnf
- **Arch Linux**: pacman
- **openSUSE**: zypper

### Flatpak
Sandboxed applications from Flathub:
- Distribution-agnostic
- Automatic dependency handling
- Isolated from system libraries

### Snap
Canonical's universal package format:
- Auto-updating
- Sandboxed
- Available on supported distributions

## Application Categories

### Browsers
| Application | Description | Package | Flatpak |
|-------------|-------------|---------|---------|
| Firefox | Mozilla Firefox | firefox | org.mozilla.firefox |
| Chromium | Open-source Chrome | chromium | org.chromium.Chromium |
| Brave | Privacy-focused browser | brave-browser | com.brave.Browser |
| LibreWolf | Firefox fork | - | io.gitlab.librewolf-community |

### Media Players
| Application | Description | Package | Flatpak |
|-------------|-------------|---------|---------|
| VLC | Universal media player | vlc | org.videolan.VLC |
| mpv | Lightweight player | mpv | io.mpv.Mpv |
| Celluloid | GTK frontend for mpv | celluloid | io.github.celluloid_player.Celluloid |

### Graphics & Design
| Application | Description | Package | Flatpak |
|-------------|-------------|---------|---------|
| GIMP | Image editor | gimp | org.gimp.GIMP |
| Inkscape | Vector graphics | inkscape | org.inkscape.Inkscape |
| Krita | Digital painting | krita | org.kde.krita |
| Blender | 3D creation suite | blender | org.blender.Blender |
| darktable | Photography workflow | darktable | org.darktable.Darktable |

### Video Editing
| Application | Description | Package | Flatpak |
|-------------|-------------|---------|---------|
| Kdenlive | Professional video editor | kdenlive | org.kde.kdenlive |
| Shotcut | Cross-platform editor | shotcut | org.shotcut.Shotcut |
| OBS Studio | Streaming/recording | obs-studio | com.obsproject.Studio |
| HandBrake | Video transcoder | handbrake | fr.handbrake.ghb |

### Development
| Application | Description | Package | Flatpak |
|-------------|-------------|---------|---------|
| VS Code | Code editor | code | com.visualstudio.code |
| Neovim | Modern Vim | neovim | - |
| Git | Version control | git | - |
| Docker | Containers | docker | - |
| Podman | Daemonless containers | podman | - |

### Gaming
| Application | Description | Package | Flatpak |
|-------------|-------------|---------|---------|
| Steam | Gaming platform | steam | com.valvesoftware.Steam |
| Lutris | Game manager | lutris | net.lutris.Lutris |
| Heroic | Epic/GOG launcher | - | com.heroicgameslauncher.hgl |
| ProtonUp-Qt | Proton manager | - | net.davidotek.pupgui2 |

### Office
| Application | Description | Package | Flatpak |
|-------------|-------------|---------|---------|
| LibreOffice | Office suite | libreoffice | org.libreoffice.LibreOffice |
| ONLYOFFICE | Modern office | - | org.onlyoffice.desktopeditors |
| Obsidian | Note-taking | - | md.obsidian.Obsidian |

## Application Presets

Pre-configured application bundles for quick setup:

### Minimal Essentials
Core utilities for any system:
- vim, nano, mc
- curl, wget, git
- htop, neofetch
- Archive tools (zip, 7zip)

### Developer Workstation
Programming tools and utilities:
- Build essentials (gcc, make, cmake)
- Python, Node.js, Go, Rust
- Docker, Podman
- VS Code, debugging tools

### Content Creator
Media production tools:
- Video editors (Kdenlive, OBS)
- Graphics (GIMP, Inkscape, Krita)
- Audio (Audacity)
- 3D (Blender)

### Gaming Setup
Gaming platforms and tools:
- Steam, Lutris, Heroic
- Wine, Proton management
- GameMode, MangoHud
- Discord

### Office Productivity
Business applications:
- LibreOffice
- Email clients
- PDF tools
- Note-taking apps

## Usage

### Interactive (TUI)
```bash
ultimate-suite
# Navigate to: Application Installer
```

### Queue Management
1. Browse categories and select applications
2. Add applications to the installation queue
3. Review queue before installation
4. Execute batch installation

### Command Line
```bash
# Install specific application
ultimate-suite --apps install firefox

# Install from preset
ultimate-suite --apps presets developer

# Search applications
ultimate-suite --apps search video
```

## Backend Selection

Choose installation method:
- **Auto**: Prefers Flatpak, falls back to native
- **Native Only**: System packages only
- **Flatpak Only**: Flatpak packages only
- **Snap Only**: Snap packages only

## Post-Installation

Some applications require additional setup:
- Docker: User added to docker group (logout required)
- Gaming: 32-bit libraries enabled on Debian/Ubuntu
- Flatpak: Flathub repository configured

## Troubleshooting

### Application Not Found
- Check if the package name is correct for your distribution
- Try alternative backend (Flatpak/Snap)
- Update package manager cache

### Installation Fails
- Check internet connectivity
- Ensure sufficient disk space
- Review logs in `~/.suite-logs/`

### Flatpak Issues
```bash
# Repair Flatpak
flatpak repair --user

# Update remotes
flatpak remote-modify --enable flathub
```
