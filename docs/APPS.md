# Application Management Guide

Ultimate Linux Suite provides a comprehensive application installer with support for native packages, Flatpak, and Snap.

## Overview

The application management system supports:

- Native package installation (apt, dnf, pacman, zypper)
- Flatpak applications from Flathub
- Snap packages
- Application presets for quick setup
- Queue-based batch installation

## Accessing the Application Installer

### Interactive Menu

```bash
sudo ultimate-linux-suite
# Navigate to: Application Installer
```

Or using the alias:

```bash
sudo ultimate-suite
# Navigate to: Application Installer
```

## Installation Methods

### Native Packages

Traditional distribution packages installed via the system package manager:

| Distribution | Package Manager | Example |
|--------------|-----------------|---------|
| Debian/Ubuntu | apt | `apt install firefox` |
| Fedora/RHEL | dnf | `dnf install firefox` |
| Arch Linux | pacman | `pacman -S firefox` |
| openSUSE | zypper | `zypper install firefox` |

### Flatpak

Sandboxed applications from Flathub:

- Distribution-agnostic
- Automatic dependency handling
- Isolated from system libraries
- Automatic updates

### Snap

Canonical's universal package format:

- Auto-updating
- Sandboxed
- Available on supported distributions

## Application Categories

### Web Browsers

| Application | Native Package | Flatpak ID |
|-------------|----------------|------------|
| Firefox | `firefox` | `org.mozilla.firefox` |
| Chromium | `chromium` | `org.chromium.Chromium` |
| Brave | `brave-browser` | `com.brave.Browser` |
| LibreWolf | - | `io.gitlab.librewolf-community` |

### Media Players

| Application | Native Package | Flatpak ID |
|-------------|----------------|------------|
| VLC | `vlc` | `org.videolan.VLC` |
| mpv | `mpv` | `io.mpv.Mpv` |
| Celluloid | `celluloid` | `io.github.celluloid_player.Celluloid` |

### Graphics & Design

| Application | Native Package | Flatpak ID |
|-------------|----------------|------------|
| GIMP | `gimp` | `org.gimp.GIMP` |
| Inkscape | `inkscape` | `org.inkscape.Inkscape` |
| Krita | `krita` | `org.kde.krita` |
| Blender | `blender` | `org.blender.Blender` |
| darktable | `darktable` | `org.darktable.Darktable` |

### Video Editing

| Application | Native Package | Flatpak ID |
|-------------|----------------|------------|
| Kdenlive | `kdenlive` | `org.kde.kdenlive` |
| Shotcut | `shotcut` | `org.shotcut.Shotcut` |
| OBS Studio | `obs-studio` | `com.obsproject.Studio` |
| HandBrake | `handbrake` | `fr.handbrake.ghb` |

### Development

| Application | Native Package | Flatpak ID |
|-------------|----------------|------------|
| VS Code | `code` | `com.visualstudio.code` |
| Neovim | `neovim` | - |
| Git | `git` | - |
| Docker | `docker` | - |
| Podman | `podman` | - |

### Gaming

| Application | Native Package | Flatpak ID |
|-------------|----------------|------------|
| Steam | `steam` | `com.valvesoftware.Steam` |
| Lutris | `lutris` | `net.lutris.Lutris` |
| Heroic | - | `com.heroicgameslauncher.hgl` |
| ProtonUp-Qt | - | `net.davidotek.pupgui2` |

### Office

| Application | Native Package | Flatpak ID |
|-------------|----------------|------------|
| LibreOffice | `libreoffice` | `org.libreoffice.LibreOffice` |
| ONLYOFFICE | - | `org.onlyoffice.desktopeditors` |
| Obsidian | - | `md.obsidian.Obsidian` |

## Application Presets

Pre-configured application bundles for quick setup. Presets are defined in `configs/app_presets/`.

### Minimal Essentials

Core utilities for any system:

- vim, nano, mc
- curl, wget, git
- htop, neofetch
- Archive tools (zip, p7zip)

### Developer Workstation

Programming tools and utilities:

- Build essentials (gcc, make, cmake)
- Python, Node.js, Go, Rust
- Docker, Podman
- VS Code, debugging tools
- Git and version control utilities

### Content Creator

Media production tools:

- Video editors (Kdenlive, OBS)
- Graphics (GIMP, Inkscape, Krita)
- Audio (Audacity)
- 3D modeling (Blender)

### Gaming Setup

Gaming platforms and tools:

- Steam, Lutris, Heroic
- Wine, Proton management
- GameMode, MangoHud
- Discord
- 32-bit libraries (Debian/Ubuntu)

## Queue Management

The installer uses a queue system for batch operations:

### Workflow

1. **Browse**: Select applications from categories
2. **Queue**: Add selected apps to installation queue
3. **Review**: View pending installations
4. **Execute**: Install all queued applications

### Queue Operations

| Action | Description |
|--------|-------------|
| Add to Queue | Mark application for installation |
| Remove from Queue | Unmark application |
| Clear Queue | Remove all pending items |
| View Queue | Display current queue |
| Execute Queue | Install all queued items |

## Backend Selection

Choose your preferred installation method:

| Mode | Behavior |
|------|----------|
| Auto | Prefers Flatpak if available, falls back to native |
| Native Only | System packages only |
| Flatpak Only | Flatpak packages only |
| Snap Only | Snap packages only |

## Post-Installation Notes

Some applications require additional setup:

### Docker

User must be added to the docker group:

```bash
sudo usermod -aG docker $USER
# Log out and back in for changes to take effect
```

### Gaming (Debian/Ubuntu)

32-bit libraries are automatically enabled:

```bash
sudo dpkg --add-architecture i386
sudo apt update
```

### Flatpak

Flathub repository is automatically configured:

```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

## Troubleshooting

### Application Not Found

- Verify the package name is correct for your distribution
- Try an alternative backend (Flatpak/Snap)
- Update package manager cache:

```bash
# Debian/Ubuntu
sudo apt update

# Fedora
sudo dnf makecache

# Arch
sudo pacman -Sy
```

### Installation Fails

- Check internet connectivity
- Ensure sufficient disk space
- Review logs: `~/.suite-logs/`
- Try installing manually to see detailed errors

### Flatpak Issues

```bash
# Repair Flatpak installation
flatpak repair --user

# Re-enable Flathub
flatpak remote-modify --enable flathub

# Update all Flatpaks
flatpak update
```

### Snap Issues

```bash
# Check snapd status
systemctl status snapd

# Restart snapd
sudo systemctl restart snapd

# Refresh all snaps
sudo snap refresh
```

## Configuration Files

### Preset Location

```
configs/app_presets/
├── gaming.conf
├── developer.conf
├── creator.conf
└── minimal.conf
```

### Preset Format

```ini
[preset]
name=My Custom Preset
description=Description of the preset

[packages]
package1=Description of package1
package2=Description of package2

[flatpak]
org.example.App=Description
```

## Adding Custom Presets

1. Create a new `.conf` file in `configs/app_presets/`
2. Follow the preset format above
3. Restart the suite to load the new preset

## Best Practices

1. **Use Presets**: Start with a preset matching your use case
2. **Prefer Native for System Tools**: Use native packages for CLI utilities
3. **Prefer Flatpak for Desktop Apps**: Better sandboxing and updates
4. **Queue Multiple Apps**: More efficient than one-by-one installation
5. **Check Disk Space**: Large presets may require several GB
