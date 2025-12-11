# Changelog

All notable changes to Ultimate Linux Suite will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-11

### Added

#### Core Features
- OS detection engine with automatic backend loading
- Hardware detection engine (CPU, GPU, storage, memory, network, form factor)
- Interactive TUI menu system with dialog support
- Logging framework with debug mode and file output

#### System Optimization
- Optimization profiles: desktop, server, laptop, gaming, VM
- Auto-optimization based on detected hardware
- Sysctl parameter management
- I/O scheduler optimization
- CPU governor configuration

#### Application Installer
- Queue-based batch installation
- Application presets: gaming, developer, creator, minimal
- Native package manager support (apt, dnf, pacman, zypper)
- Flatpak integration with Flathub
- Snap package support

#### Driver Manager
- Realtek r8152 USB Ethernet support
- Realtek r8821cu USB WiFi support
- Broadcom WiFi driver installation
- DKMS module management
- GPU driver guidance (NVIDIA, AMD, Intel)
- Driver vault for offline installation

#### Recovery Tools
- System health checks
- Package manager repair (APT, DNF, Pacman, Zypper)
- Initramfs regeneration
- GRUB bootloader management
- Network repair tools
- Configuration backup and restore
- Package list backup and restore

#### Distribution Support
- Debian family: Debian, Ubuntu, Linux Mint, Kali, Parrot
- Fedora family: Fedora, RHEL, CentOS, Rocky, AlmaLinux
- Arch family: Arch Linux, Manjaro, EndeavourOS
- SUSE family: openSUSE Leap, openSUSE Tumbleweed

#### Packaging & Build System
- Debian packaging (.deb) with dpkg-buildpackage
- RPM packaging (.rpm) with rpmbuild
- Local build system (`build.sh`, `Makefile`)
- GitHub Actions workflow for automated package builds
- Shell completions for Bash, Zsh, and Fish

### Commands
- Primary command: `ultimate-linux-suite`
- Alias command: `ultimate-suite`

## [0.1.0] - 2025-12-11

### Added
- Initial development release
- Core architecture and module system
- Basic optimization and recovery tools
- Multi-distribution backend framework
