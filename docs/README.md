# Ultimate Linux Suite Documentation

Welcome to the Ultimate Linux Suite documentation. This guide provides comprehensive information about the toolkit's architecture, features, and usage.

## Overview

Ultimate Linux Suite is a modular, distribution-agnostic toolkit for Linux system optimization, application management, driver installation, and system recovery. It provides both an interactive TUI (Text User Interface) and command-line options for all operations.

### Commands

| Command | Description |
|---------|-------------|
| `ultimate-linux-suite` | Primary command (installed via package) |
| `ultimate-suite` | Alias command (shorter alternative) |
| `./suite.sh` | Direct execution from source |

## Documentation Index

| Document | Description |
|----------|-------------|
| [USAGE.md](USAGE.md) | Command-line options, menu navigation, and general usage |
| [OPTIMIZATION.md](OPTIMIZATION.md) | System optimization profiles, sysctl parameters, I/O schedulers |
| [APPS.md](APPS.md) | Application installer, presets, Flatpak/Snap support |
| [DRIVERS.md](DRIVERS.md) | Driver management for Realtek, Broadcom, and GPU guidance |
| [RECOVERY.md](RECOVERY.md) | System repair, backup/restore, bootloader management |

## Supported Distributions

### Debian Family
- Debian 10+ (Buster, Bullseye, Bookworm)
- Ubuntu 20.04+ (Focal, Jammy, Noble)
- Linux Mint 20+
- Kali Linux
- Parrot OS

### Fedora Family
- Fedora 38+
- RHEL 8+
- CentOS Stream 8+
- Rocky Linux 8+
- AlmaLinux 8+

### Arch Family
- Arch Linux
- Manjaro
- EndeavourOS

### SUSE Family
- openSUSE Leap 15+
- openSUSE Tumbleweed

## System Requirements

### Required
| Component | Requirement |
|-----------|-------------|
| Shell | Bash 4.0 or higher |
| TUI | dialog package |
| Utilities | coreutils, procps, util-linux |
| Privileges | Root access for system modifications |

### Recommended
| Component | Purpose |
|-----------|---------|
| pciutils | PCI device detection (`lspci`) |
| usbutils | USB device detection (`lsusb`) |
| dmidecode | System hardware information |
| lshw | Detailed hardware listing |

### Optional
| Component | Purpose |
|-----------|---------|
| flatpak | Flatpak application support |
| snapd | Snap package support |
| dkms | Dynamic kernel module compilation |

## Architecture

### Modular Design

```
┌─────────────────────────────────────────────────────────┐
│                      suite.sh                           │
│                   (Main Entry Point)                    │
└─────────────────────┬───────────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        ▼                           ▼
┌───────────────┐           ┌───────────────┐
│     lib/      │           │   backends/   │
│  Core Libs    │           │  OS-Specific  │
├───────────────┤           ├───────────────┤
│ logging.sh    │           │ debian.sh     │
│ utils.sh      │           │ ubuntu.sh     │
│ os_detect.sh  │           │ fedora.sh     │
│ hardware.sh   │           │ arch.sh       │
│ pkg.sh        │           │ opensuse.sh   │
│ menu.sh       │           │ ...           │
└───────────────┘           └───────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────┐
│                      modules/                          │
│                  Feature Modules                       │
├───────────────┬───────────────┬───────────────────────┤
│ optimize.sh   │ apps.sh       │ drivers.sh            │
│ recovery.sh   │ setup_profiles│                       │
└───────────────┴───────────────┴───────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────┐
│                       menus/                           │
│                  User Interface                        │
├───────────────┬───────────────┬───────────────────────┤
│ main_menu.sh  │ optimize_menu │ apps_menu.sh          │
│ drivers_menu  │ recovery_menu │                       │
└───────────────┴───────────────┴───────────────────────┘
```

### Component Responsibilities

| Component | Responsibility |
|-----------|----------------|
| **lib/** | Core utilities, logging, OS/hardware detection, package abstraction |
| **backends/** | Distribution-specific package names and commands |
| **modules/** | Feature implementations (optimization, apps, drivers, recovery) |
| **menus/** | Interactive TUI menu implementations |
| **configs/** | Configuration files and application presets |
| **drivers/** | Driver source vault for offline installation |

### OS Detection Flow

1. Read `/etc/os-release` for distribution ID
2. Match against known distribution families
3. Load appropriate backend from `backends/`
4. Initialize distribution-specific functions

### Hardware Detection

The hardware detection engine identifies:

| Hardware | Detection Method |
|----------|------------------|
| CPU | `/proc/cpuinfo`, `lscpu` |
| GPU | `lspci`, driver modules |
| Storage | `lsblk`, `/sys/block/` |
| Memory | `/proc/meminfo` |
| Network | `ip link`, `lspci`, `lsusb` |
| Form Factor | DMI data, battery presence |

## Configuration Files

### Optimization Profiles

Located at `configs/optimization_profiles.conf`:

```ini
[desktop]
swappiness=10
vfs_cache_pressure=50
dirty_ratio=20
...

[server]
swappiness=1
vfs_cache_pressure=100
dirty_ratio=40
...
```

### Application Presets

Located at `configs/app_presets/`:

| Preset | Description |
|--------|-------------|
| `gaming.conf` | Steam, Lutris, Wine, GameMode |
| `developer.conf` | Git, Docker, VS Code, build tools |
| `creator.conf` | GIMP, Blender, OBS, Kdenlive |
| `minimal.conf` | Essential CLI utilities |

## Building and Packaging

### Local Build System

```bash
# Build Debian package
./build.sh deb

# Build RPM package
./build.sh rpm

# Build all packages
./build.sh all

# Clean build artifacts
./build.sh clean
```

### Makefile Targets

```bash
make deb      # Build .deb
make rpm      # Build .rpm
make all      # Build all
make clean    # Clean artifacts
```

### GitHub Actions

Push a version tag to trigger automatic package builds:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Getting Help

- **In-app help**: `ultimate-linux-suite --help`
- **Repository**: https://github.com/Nerds489/ultimate-linux-suite
- **Issues**: https://github.com/Nerds489/ultimate-linux-suite/issues

## License

Ultimate Linux Suite is released under the MIT License. See [LICENSE](../LICENSE) for details.
