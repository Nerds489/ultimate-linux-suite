# Ultimate Linux Suite - Usage Guide

This guide covers command-line options, menu navigation, and general usage of Ultimate Linux Suite.

## Running the Suite

### Installed via Package

```bash
# Primary command
sudo ultimate-linux-suite

# Alias command (shorter)
sudo ultimate-suite
```

### Running from Source

```bash
# From the repository directory
sudo ./suite.sh

# From any location
sudo /path/to/ultimate-linux-suite/suite.sh
```

## Command-Line Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Display help message and exit |
| `-v`, `--version` | Display version information and exit |
| `--no-color` | Disable colored output |
| `--debug` | Enable debug logging (verbose output) |
| `--log-file FILE` | Write logs to the specified file |
| `--no-welcome` | Skip the welcome screen |

### Examples

```bash
# Show help
ultimate-linux-suite --help

# Show version
ultimate-linux-suite --version

# Run with debug output
sudo ultimate-linux-suite --debug

# Log all output to a file
sudo ultimate-linux-suite --log-file ~/suite.log

# Combine options
sudo ultimate-linux-suite --debug --log-file /tmp/debug.log

# Skip welcome screen
sudo ultimate-linux-suite --no-welcome

# Run without colors (useful for scripts or logging)
sudo ultimate-linux-suite --no-color
```

## Main Menu Navigation

When launched, the suite presents an interactive text-based menu:

```
╔════════════════════════════════════════════════════════════════╗
║  Ultimate Linux Suite - Main Menu                              ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║   1) System Optimization                                       ║
║   2) Application Installer                                     ║
║   3) Driver Manager                                            ║
║   4) Recovery & Tools                                          ║
║   5) System Information                                        ║
║   0) Exit                                                      ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
```

### Menu Interface

If `dialog` is installed, you get an enhanced graphical TUI. Otherwise, the suite falls back to a basic text interface that works in any terminal.

### Navigation Keys

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate menu items |
| `Enter` | Select highlighted item |
| `Tab` | Switch between buttons (OK/Cancel) |
| `Esc` | Go back / Cancel |
| Number keys | Quick select menu item |

## Menu Sections

### 1. System Optimization

Access system performance tuning:

- **Auto Optimize**: Automatically apply optimizations based on detected hardware
- **Select Profile**: Choose from desktop, server, laptop, gaming, or VM profiles
- **Kernel Tweaks**: Manually configure swappiness, I/O schedulers, and sysctl parameters
- **Service Manager**: Enable/disable system services

See [OPTIMIZATION.md](OPTIMIZATION.md) for detailed information.

### 2. Application Installer

Install applications with queue management:

- **Browse Categories**: Select apps by category (browsers, media, development, etc.)
- **Use Presets**: Install curated application bundles (gaming, developer, creator)
- **Manage Queue**: Review and execute pending installations
- **Flatpak/Snap**: Install from alternative package sources

See [APPS.md](APPS.md) for detailed information.

### 3. Driver Manager

Hardware detection and driver installation:

- **Scan Hardware**: Detect GPUs, WiFi adapters, and other devices
- **Install Drivers**: Realtek, Broadcom, and other supported hardware
- **GPU Guidance**: Non-aggressive guidance for NVIDIA/AMD/Intel drivers
- **DKMS Management**: Rebuild kernel modules

See [DRIVERS.md](DRIVERS.md) for detailed information.

### 4. Recovery & Tools

System repair and maintenance:

- **Health Check**: Comprehensive system diagnostics
- **Package Repair**: Fix broken packages and dependencies
- **Initramfs**: Regenerate initial ramdisk
- **GRUB Tools**: Bootloader management
- **Network Repair**: Fix connectivity issues
- **Backup/Restore**: Configuration and package list backup

See [RECOVERY.md](RECOVERY.md) for detailed information.

### 5. System Information

View detected system information:

- Distribution and version
- Kernel version
- CPU details (vendor, model, cores)
- GPU information
- Memory and swap
- Storage devices
- Network interfaces

## Running as Root

Most operations require root privileges. The suite uses `sudo` when needed, but for full functionality:

```bash
sudo ultimate-linux-suite
```

If run without root, the suite will prompt for elevation when required.

## Logging

### Debug Mode

Enable verbose output to troubleshoot issues:

```bash
sudo ultimate-linux-suite --debug
```

### Log to File

Capture all output for later review:

```bash
sudo ultimate-linux-suite --log-file ~/suite-$(date +%Y%m%d).log
```

### Combined Debug and File Logging

```bash
sudo ultimate-linux-suite --debug --log-file ~/debug.log
```

## Headless and Script Usage

### Disable Colors

For scripts or when piping output:

```bash
sudo ultimate-linux-suite --no-color 2>&1 | tee output.log
```

### Non-Interactive Mode

The suite is designed for interactive use. For automation, consider using the underlying system commands directly or scripting around specific menu operations.

## Shell Completions

The suite includes shell completions for tab-completion of commands and options.

### Bash

Completions are installed to `/etc/bash_completion.d/` when using packages.

For manual installation:
```bash
source completions/ultimate-linux-suite.bash
```

### Zsh

Completions are installed to `/usr/share/zsh/site-functions/`.

For manual installation:
```bash
fpath=(completions $fpath)
compinit
```

### Fish

Completions are installed to `/usr/share/fish/vendor_completions.d/`.

For manual installation:
```bash
cp completions/ultimate-linux-suite.fish ~/.config/fish/completions/
```

## Troubleshooting

### Menu Not Displaying Correctly

Install the dialog package:

```bash
# Debian/Ubuntu
sudo apt install dialog

# Fedora
sudo dnf install dialog

# Arch
sudo pacman -S dialog

# openSUSE
sudo zypper install dialog
```

### Permission Denied

Ensure the script is executable:

```bash
chmod +x suite.sh
```

Run with sudo:

```bash
sudo ./suite.sh
```

### Backend Not Loading

Check OS detection with debug mode:

```bash
sudo ultimate-linux-suite --debug 2>&1 | grep -i "backend\|os_id\|distro"
```

### Package Operations Fail

Verify the package manager is working:

```bash
# Debian/Ubuntu
sudo apt update

# Fedora
sudo dnf check-update

# Arch
sudo pacman -Sy

# openSUSE
sudo zypper refresh
```

### Terminal Too Small

The TUI requires a minimum terminal size. Resize your terminal window or use a larger console.

## Quick Reference

| Task | Command |
|------|---------|
| Launch interactive menu | `sudo ultimate-linux-suite` |
| Show help | `ultimate-linux-suite --help` |
| Show version | `ultimate-linux-suite --version` |
| Debug mode | `sudo ultimate-linux-suite --debug` |
| Log to file | `sudo ultimate-linux-suite --log-file FILE` |
| No colors | `ultimate-linux-suite --no-color` |
