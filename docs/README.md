# Ultimate Linux Suite

A comprehensive, modular Linux system optimization and management toolkit.

## Features

- **System Optimization** - Kernel tweaks, service management, storage optimization
- **Application Installer** - Curated presets and package management across distros
- **Driver Manager** - GPU, WiFi, audio driver detection and installation
- **Recovery Tools** - Backup, restore, and system repair utilities

## Supported Distributions

### Debian Family
- Debian
- Ubuntu / Pop!_OS / Elementary OS
- Linux Mint / LMDE
- Kali Linux
- Parrot OS

### Fedora Family
- Fedora
- RHEL / CentOS / Rocky / AlmaLinux

### Arch Family
- Arch Linux
- Manjaro
- EndeavourOS

### SUSE Family
- openSUSE Leap
- openSUSE Tumbleweed

## Requirements

- Bash 4.0 or higher
- Standard Linux utilities (grep, sed, awk)
- dialog or whiptail (optional, for enhanced menus)
- Root privileges for system modifications

## Installation

```bash
# Clone or download the suite
git clone https://github.com/yourusername/ultimate-linux-suite.git

# Or extract the archive
tar -xzf ultimate-linux-suite.tar.gz

# Make executable
chmod +x ultimate-linux-suite/suite.sh

# Run
./ultimate-linux-suite/suite.sh
```

## Quick Start

```bash
# Run with default settings
./suite.sh

# Show help
./suite.sh --help

# Run with debug logging
./suite.sh --debug

# Disable colors for script output
./suite.sh --no-color

# Log to file
./suite.sh --log-file /path/to/logfile.log
```

## Project Structure

```
ultimate-linux-suite/
├── suite.sh              # Main entry point
├── lib/                  # Core libraries
│   ├── logging.sh        # Logging functions
│   ├── utils.sh          # Utility functions
│   ├── os_detect.sh      # OS detection
│   ├── hardware_detect.sh# Hardware detection
│   ├── pkg.sh            # Package management
│   └── menu.sh           # Menu framework
├── modules/              # Functional modules
│   ├── optimize.sh       # Optimization functions
│   ├── apps.sh           # Application installer
│   ├── drivers.sh        # Driver management
│   ├── recovery.sh       # Recovery tools
│   └── setup_profiles.sh # Configuration profiles
├── backends/             # OS-specific implementations
│   ├── debian.sh
│   ├── ubuntu.sh
│   ├── fedora.sh
│   ├── arch.sh
│   └── ...
├── menus/                # Menu implementations
│   ├── main_menu.sh
│   ├── optimize_menu.sh
│   └── ...
├── configs/              # Configuration files
│   ├── optimization_profiles.conf
│   └── app_presets/
└── docs/                 # Documentation
    ├── README.md
    └── USAGE.md
```

## Architecture

The suite uses a modular architecture:

1. **Libraries** (`lib/`) - Core functionality shared across all components
2. **Backends** (`backends/`) - OS-specific implementations
3. **Modules** (`modules/`) - Feature implementations
4. **Menus** (`menus/`) - User interface components
5. **Configs** (`configs/`) - Configuration files and presets

### OS Detection

The suite automatically detects:
- Distribution ID and family
- Version information
- Package manager
- Loads appropriate backend

### Hardware Detection

Detected hardware includes:
- CPU (vendor, model, cores, capabilities)
- GPU (vendor, type, driver)
- Memory (RAM, swap)
- Storage (type, filesystem)
- Network interfaces
- Form factor (laptop/desktop/server/VM)

## Customization

### Adding New Backends

Create a new file in `backends/` following the template:

```bash
#!/usr/bin/env bash
# myos.sh - Custom Backend

readonly BACKEND_NAME="myos"

backend_init() {
    log_info "Initializing MyOS backend"
}

backend_install_packages() {
    # Implementation
}

backend_post_setup() {
    # Implementation
}
```

### Adding Application Presets

Create a new `.conf` file in `configs/app_presets/`:

```ini
[preset]
name=My Preset
description=Custom application set

[packages]
package1=Description
package2=Description
```

## License

MIT License

## Contributing

Contributions are welcome. Please submit issues and pull requests.
