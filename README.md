# Ultimate Linux Suite

Ultimate Linux Suite is a modular, interactive toolkit for Linux system optimization, application installation, driver management, and recovery.

## Features

- **Multi-distribution support** - Debian, Ubuntu, Mint, Fedora, Arch, openSUSE, and more
- **Hardware detection** - Automatic hardware profiling and optimization recommendations
- **System optimization** - Desktop, server, laptop, gaming, and VM profiles
- **Application management** - Install apps via native packages, Flatpak, or Snap with queue management
- **Driver management** - Realtek, Broadcom, GPU drivers with DKMS support
- **Recovery tools** - System health checks, package repair, bootloader management, backups

## Quick Start

```bash
git clone https://github.com/Nerds489/ultimate-linux-suite.git
cd ultimate-linux-suite
chmod +x suite.sh
sudo ./suite.sh
```

Or, if installed via package:

```bash
sudo ultimate-linux-suite
# or use the short alias:
sudo ultimate-suite
```

## Requirements

- Bash 4.0+
- dialog
- Root/sudo privileges for system modifications

## Documentation

Detailed documentation is available in the `docs/` directory:

- [USAGE.md](docs/USAGE.md) - General usage guide
- [OPTIMIZATION.md](docs/OPTIMIZATION.md) - System optimization details
- [APPS.md](docs/APPS.md) - Application management guide
- [DRIVERS.md](docs/DRIVERS.md) - Driver installation guide
- [RECOVERY.md](docs/RECOVERY.md) - Recovery and repair tools

## Installation

### From Source

```bash
git clone https://github.com/Nerds489/ultimate-linux-suite.git
cd ultimate-linux-suite
sudo ./suite.sh
```

### Debian/Ubuntu (.deb)

```bash
# Build the package
cd packaging/debian
dpkg-buildpackage -us -uc

# Install
sudo dpkg -i ../ultimate-linux-suite_*.deb
```

### Fedora/RHEL (.rpm)

```bash
# Build the package
rpmbuild -ba packaging/rpm/ultimate-linux-suite.spec

# Install
sudo rpm -i ~/rpmbuild/RPMS/noarch/ultimate-linux-suite-*.rpm
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests at:
https://github.com/Nerds489/ultimate-linux-suite
