# Ultimate Linux Suite

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Build Packages](https://img.shields.io/github/actions/workflow/status/Nerds489/ultimate-linux-suite/build-packages.yml?label=packages)](https://github.com/Nerds489/ultimate-linux-suite/actions)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](CHANGELOG.md)

A comprehensive, modular Linux system optimization and management toolkit. Ultimate Linux Suite provides interactive tools for system optimization, application installation, driver management, and system recovery across multiple Linux distributions.

## Features Overview

| Feature | Description |
|---------|-------------|
| **OS Detection Engine** | Automatic distribution detection with backend loading |
| **Hardware Detection** | CPU, GPU, storage, memory, and form factor profiling |
| **System Optimization** | Profile-based kernel tuning (desktop, server, laptop, gaming, VM) |
| **Application Installer** | Queue-based installation with presets (gaming, developer, creator) |
| **Driver Manager** | Realtek, Broadcom WiFi, and GPU driver guidance |
| **Recovery Tools** | Package repair, initramfs, GRUB, network diagnostics |
| **Backup & Restore** | Configuration and package list backup/restore |

## Supported Distributions

- **Debian Family**: Debian, Ubuntu, Linux Mint, Kali Linux, Parrot OS
- **Fedora Family**: Fedora, RHEL, CentOS, Rocky Linux, AlmaLinux
- **Arch Family**: Arch Linux, Manjaro, EndeavourOS
- **SUSE Family**: openSUSE Leap, openSUSE Tumbleweed

## Quick Start

### From Source

```bash
git clone https://github.com/Nerds489/ultimate-linux-suite.git
cd ultimate-linux-suite
sudo ./suite.sh
```

### From Package

```bash
# Primary command
sudo ultimate-linux-suite

# Alias command
sudo ultimate-suite
```

## Installation

### Option 1: Clone and Run

```bash
git clone https://github.com/Nerds489/ultimate-linux-suite.git
cd ultimate-linux-suite
chmod +x suite.sh
sudo ./suite.sh
```

### Option 2: Debian/Ubuntu (.deb)

Download from [Releases](https://github.com/Nerds489/ultimate-linux-suite/releases) or build locally:

```bash
# Build the package
./build.sh deb

# Install
sudo dpkg -i ../ultimate-linux-suite_*.deb
sudo apt-get install -f  # Fix dependencies if needed
```

### Option 3: Fedora/RHEL (.rpm)

Download from [Releases](https://github.com/Nerds489/ultimate-linux-suite/releases) or build locally:

```bash
# Build the package
./build.sh rpm

# Install
sudo rpm -i ~/rpmbuild/RPMS/noarch/ultimate-linux-suite-*.rpm
```

## Requirements

| Requirement | Notes |
|-------------|-------|
| Bash 4.0+ | Required |
| dialog | Required for TUI menus |
| Root/sudo | Required for system modifications |
| pciutils, usbutils | Recommended for hardware detection |
| flatpak | Optional for Flatpak app support |

## Project Structure

```
ultimate-linux-suite/
├── suite.sh                  # Main entry point
├── build.sh                  # Local build system
├── Makefile                  # Build system wrapper
├── lib/                      # Core libraries
│   ├── logging.sh            # Logging functions
│   ├── utils.sh              # Utility functions
│   ├── os_detect.sh          # OS detection engine
│   ├── hardware_detect.sh    # Hardware detection engine
│   ├── pkg.sh                # Package management abstraction
│   └── menu.sh               # Menu framework
├── modules/                  # Feature modules
│   ├── optimize.sh           # System optimization
│   ├── apps.sh               # Application installer
│   ├── drivers.sh            # Driver management
│   ├── recovery.sh           # Recovery tools
│   └── setup_profiles.sh     # Profile configuration
├── menus/                    # Menu implementations
│   ├── main_menu.sh
│   ├── optimize_menu.sh
│   ├── apps_menu.sh
│   ├── drivers_menu.sh
│   └── recovery_menu.sh
├── backends/                 # Distribution-specific backends
│   ├── debian.sh
│   ├── ubuntu.sh
│   ├── fedora.sh
│   ├── arch.sh
│   ├── opensuse.sh
│   └── ...
├── configs/                  # Configuration files
│   ├── optimization_profiles.conf
│   └── app_presets/
│       ├── gaming.conf
│       ├── developer.conf
│       ├── creator.conf
│       └── minimal.conf
├── drivers/                  # Driver vault (offline sources)
│   ├── realtek-r8152/
│   ├── realtek-r8821cu/
│   ├── broadcom/
│   └── ...
├── completions/              # Shell completions
│   ├── ultimate-linux-suite.bash
│   ├── ultimate-linux-suite.zsh
│   └── ultimate-linux-suite.fish
├── packaging/                # Package build files
│   ├── debian/
│   └── rpm/
├── docs/                     # Documentation
└── .github/workflows/        # CI/CD workflows
```

## Building from Source

Ultimate Linux Suite includes a local build system for creating distribution packages.

### Using build.sh

```bash
# Build Debian package
./build.sh deb

# Build RPM package
./build.sh rpm

# Build both packages
./build.sh all

# Clean build artifacts
./build.sh clean
```

### Using Make

```bash
make deb      # Build .deb package
make rpm      # Build .rpm package
make all      # Build all packages
make clean    # Clean artifacts
```

### Build Requirements

| Package Type | Required Tools |
|--------------|----------------|
| .deb | `dpkg-dev`, `debhelper` (`apt install dpkg-dev debhelper`) |
| .rpm | `rpm-build` (`dnf install rpm-build`) |

### GitHub Actions

Packages are automatically built when pushing version tags:

```bash
git tag v1.0.0
git push origin v1.0.0
```

This triggers the build workflow and creates a GitHub Release with `.deb`, `.rpm`, and `.tar.gz` artifacts.

## Documentation

Detailed documentation is available in the `docs/` directory:

| Document | Description |
|----------|-------------|
| [USAGE.md](docs/USAGE.md) | Command-line options on menu navigation |
| [OPTIMIZATION.md](docs/OPTIMIZATION.md) | System optimization profiles and sysctl tuning |
| [APPS.md](docs/APPS.md) | Application presets and package management |
| [DRIVERS.md](docs/DRIVERS.md) | Driver installation for Realtek, Broadcom, GPUs |
| [RECOVERY.md](docs/RECOVERY.md) | System repair, backup, and recovery tools |

## Usage Examples

```bash
# Launch interactive menu
sudo ultimate-linux-suite

# Show help
ultimate-linux-suite --help

# Show version
ultimate-linux-suite --version

# Enable debug logging
sudo ultimate-linux-suite --debug

# Log to file
sudo ultimate-linux-suite --log-file ~/suite.log
```

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Test on at least one supported distribution
5. Commit with clear messages (`git commit -m "Add feature X"`)
6. Push to your fork (`git push origin feature/my-feature`)
7. Open a Pull Request

### Development Guidelines

- Follow existing code style (shellcheck compliant)
- Add distribution-specific code to `backends/`
- Add new features as modules in `modules/`
- Update documentation for user-facing changes
- Test packaging with `./build.sh all`

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Links

- **Repository**: https://github.com/Nerds489/ultimate-linux-suite
- **Issues**: https://github.com/Nerds489/ultimate-linux-suite/issues
- **Releases**: https://github.com/Nerds489/ultimate-linux-suite/releases
