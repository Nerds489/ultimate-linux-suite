# Ultimate Linux Suite - Usage Guide

## Running the Suite

### Basic Usage

```bash
# Run the suite
./suite.sh

# Or from any location
/path/to/ultimate-linux-suite/suite.sh
```

### Command Line Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-v, --version` | Show version information |
| `--no-color` | Disable colored output |
| `--debug` | Enable debug logging |
| `--log-file FILE` | Write logs to specified file |
| `--no-welcome` | Skip welcome screen |

### Examples

```bash
# Run with debug output
./suite.sh --debug

# Log to file
./suite.sh --log-file ~/suite.log

# Run without colors (for scripts)
./suite.sh --no-color

# Combine options
./suite.sh --debug --log-file /tmp/debug.log
```

## Main Menu Navigation

The suite presents a text-based menu interface:

```
╔════════════════════════════════════════════════════════════════╗
║  Main Menu                                                      ║
╠════════════════════════════════════════════════════════════════╣
║                                                                  ║
║   1) System Optimization                                        ║
║   2) Application Installer                                      ║
║   3) Driver Manager                                             ║
║   4) Recovery & Tools                                           ║
║   5) System Information                                         ║
║   0) Exit                                                       ║
║                                                                  ║
╚════════════════════════════════════════════════════════════════╝
```

If `dialog` or `whiptail` is installed, you'll get an enhanced graphical menu.

## System Optimization

### Optimization Profiles

Pre-configured profiles for common use cases:

| Profile | Use Case | Settings |
|---------|----------|----------|
| Desktop | General use | Balanced swappiness, schedutil governor |
| Gaming | Low latency | Low swappiness, performance governor |
| Server | Throughput | Moderate swappiness, ondemand governor |
| Laptop | Battery | Power-saving governor |
| Workstation | Productivity | Balanced with performance bias |
| Minimal | Low resources | High swappiness, conservative settings |

### Kernel Tweaks

- **Swappiness** - Control memory swapping behavior (0-100)
- **I/O Scheduler** - Select optimal scheduler for your storage
- **Huge Pages** - Configure huge page support
- **Sysctl Settings** - Apply kernel parameter optimizations

### Service Manager

- List running services
- Disable unnecessary services
- Enable recommended services

## Application Installer

### Using Presets

Presets install curated sets of applications:

| Preset | Applications |
|--------|-------------|
| Gaming | Steam, Lutris, Wine, GameMode |
| Developer | Git, VS Code, Docker, Python, Node.js |
| Creator | GIMP, Blender, OBS, Audacity |
| Minimal | Vim, htop, curl, git |
| Office | LibreOffice, Thunderbird |

### Installing by Category

Browse and install applications by category:
- Web Browsers
- Media Players
- Graphics & Design
- Development Tools
- Office Applications
- Utilities
- Games

### Flatpak Support

The suite supports Flatpak applications:
- Install Flatpak apps
- List installed Flatpaks
- Update all Flatpaks

## Driver Manager

### Hardware Detection

The suite detects:
- GPU (NVIDIA/AMD/Intel)
- WiFi chipset
- Audio subsystem
- Storage type

### GPU Drivers

| Vendor | Options |
|--------|---------|
| NVIDIA | Proprietary (recommended), Nouveau |
| AMD | Mesa/AMDGPU (open), AMDGPU Pro |
| Intel | i915 (built-in) |

### WiFi Drivers

Supported chipsets:
- Broadcom
- Realtek
- Intel
- Atheros/Qualcomm

### Auto-Install

On supported systems (Ubuntu with ubuntu-drivers), automatic driver installation is available.

## Recovery & Tools

### Backup Manager

- **Home Directory** - Backup user files
- **System Backup** - Full system backup
- **Package List** - Export installed packages
- **Configurations** - Backup config files

### Restore

- Restore from backups
- Reinstall packages from exported list

### Repair Tools

- Fix package manager issues
- Repair broken dependencies
- Reset network configuration

### Disk Utilities

- View disk usage
- Check SMART status
- Run TRIM (SSD)
- Filesystem check

### System Logs

View various system logs:
- System journal
- Boot messages
- Kernel log (dmesg)
- Authentication log

## Tips

### Running as Root

Some operations require root privileges. The suite will use `sudo` when needed. For full functionality:

```bash
sudo ./suite.sh
```

### Logging

Enable debug logging to troubleshoot issues:

```bash
./suite.sh --debug --log-file ~/suite-debug.log
```

### Headless Systems

For systems without dialog/whiptail, the suite falls back to a text-based interface that works in any terminal.

### Scripting

Use `--no-color` when capturing output:

```bash
./suite.sh --no-color 2>&1 | tee output.log
```

## Troubleshooting

### Menu Not Displaying Correctly

Install dialog for better menus:

```bash
# Debian/Ubuntu
sudo apt install dialog

# Fedora
sudo dnf install dialog

# Arch
sudo pacman -S dialog
```

### Permission Denied

Ensure the script is executable:

```bash
chmod +x suite.sh
```

### Backend Not Loading

Check OS detection:

```bash
./suite.sh --debug 2>&1 | grep -i "backend\|os_id"
```

### Package Installation Fails

Verify package manager is working:

```bash
# Debian/Ubuntu
sudo apt update

# Fedora
sudo dnf check-update

# Arch
sudo pacman -Sy
```
