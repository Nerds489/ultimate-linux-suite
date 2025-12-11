# Driver Management Guide

Ultimate Linux Suite provides hardware detection and driver management for common devices including Realtek USB network adapters, Broadcom WiFi, and GPU guidance.

## Overview

The driver management system:

- Detects hardware requiring drivers
- Manages DKMS kernel modules
- Provides a driver vault for offline installation
- Offers safe GPU driver guidance (non-aggressive)

## Accessing the Driver Manager

### Interactive Menu

```bash
sudo ultimate-linux-suite
# Navigate to: Driver Manager
```

Or using the alias:

```bash
sudo ultimate-suite
# Navigate to: Driver Manager
```

## Supported Hardware

### Realtek r8152 USB Ethernet

USB Ethernet adapters using the RTL8152/8153/8156 chipset:

| Property | Value |
|----------|-------|
| USB Vendor ID | 0bda |
| Product IDs | 8152, 8153, 8156 |
| Common devices | USB 2.5GbE adapters, USB-C docking stations |

### Realtek r8821cu USB WiFi

USB WiFi adapters using the RTL8821CU chipset:

| Property | Value |
|----------|-------|
| USB Vendor ID | 0bda |
| Product IDs | c811, c82c, c821, b820, c820 |
| Common devices | Budget USB WiFi dongles |

### Broadcom WiFi

PCI/PCIe WiFi adapters from Broadcom:

- Common in laptops (especially older MacBooks)
- Requires proprietary `wl` driver for best support
- Alternative: `b43` open-source driver (limited support)

### GPU Drivers

Guidance for NVIDIA, AMD, and Intel GPUs:

- **Non-aggressive**: Does not auto-install GPU drivers
- Provides recommendations and commands
- User must manually install after reviewing guidance

## Hardware Detection

The driver manager detects hardware via:

| Method | Devices |
|--------|---------|
| `lspci` | PCI devices (GPU, WiFi cards) |
| `lsusb` | USB devices (Realtek adapters) |
| `lsmod` | Currently loaded kernel modules |

### Detection Output

```
=== Detected Hardware ===
  GPU: NVIDIA GeForce GTX 1080
  Broadcom WiFi: BCM4360 [detected]
  Realtek r8152: RTL8153 [detected]

=== Driver Status ===
  NVIDIA: nouveau (open-source active)
  Broadcom WiFi: needs proprietary driver
  Realtek r8152: kernel driver loaded
```

## DKMS Integration

Dynamic Kernel Module Support (DKMS) automatically rebuilds kernel modules when:

- Kernel is updated
- Module source is updated
- Manual rebuild is requested

### Installing DKMS

```bash
# Debian/Ubuntu
sudo apt install dkms linux-headers-$(uname -r)

# Fedora
sudo dnf install dkms kernel-devel

# Arch
sudo pacman -S dkms linux-headers

# openSUSE
sudo zypper install dkms kernel-devel
```

### DKMS Commands

```bash
# List installed modules
dkms status

# Rebuild all modules for current kernel
sudo dkms autoinstall

# Build specific module
sudo dkms install <module>/<version> -k $(uname -r)
```

## Driver Installation

### Realtek r8152 (USB Ethernet)

The r8152 driver is typically included in the kernel. If not working:

1. Check if driver is loaded:
   ```bash
   lsmod | grep r8152
   ```

2. Load the driver manually:
   ```bash
   sudo modprobe r8152
   ```

3. For newer devices requiring DKMS version:
   - Place driver source in driver vault
   - Use the installer menu to build and install

### Realtek r8821cu (USB WiFi)

This driver is NOT included in mainline kernels and must be built from source:

1. Download driver source:
   ```bash
   git clone https://github.com/morrownr/8821cu-20210916
   ```

2. Install via DKMS:
   ```bash
   cd 8821cu-20210916
   sudo ./dkms-install.sh
   ```

3. Load the module:
   ```bash
   sudo modprobe 8821cu
   ```

### Broadcom WiFi

#### Debian/Ubuntu

```bash
# Enable non-free repositories (if needed)
sudo apt install broadcom-sta-dkms

# Load the driver
sudo modprobe wl
```

#### Fedora

```bash
# Enable RPM Fusion (required)
sudo dnf install \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Install driver
sudo dnf install broadcom-wl akmod-wl

# Build kernel module
sudo akmods --force

# Load driver
sudo modprobe wl
```

#### Arch Linux

```bash
# From AUR (using yay or similar)
yay -S broadcom-wl-dkms

# Load driver
sudo modprobe wl
```

### GPU Drivers

The suite provides **guidance only** for GPU drivers due to their complexity and potential system impact.

#### NVIDIA

```bash
# Ubuntu (recommended method)
sudo ubuntu-drivers autoinstall
# or specific version:
sudo apt install nvidia-driver-535

# Fedora (enable RPM Fusion first)
sudo dnf install akmod-nvidia

# Arch
sudo pacman -S nvidia nvidia-utils
```

#### AMD

AMD GPUs typically work with open-source drivers (amdgpu/mesa):

```bash
# Debian/Ubuntu - ensure mesa is installed
sudo apt install mesa-vulkan-drivers mesa-va-drivers

# Fedora
sudo dnf install mesa-vulkan-drivers mesa-va-drivers

# Arch
sudo pacman -S vulkan-radeon libva-mesa-driver
```

#### Intel

Intel GPUs use the i915 driver (usually built into kernel):

```bash
# Debian/Ubuntu - video acceleration
sudo apt install intel-media-va-driver

# Fedora
sudo dnf install intel-media-driver

# Arch
sudo pacman -S intel-media-driver
```

## Driver Vault

The driver vault stores driver sources for offline installation:

```
/usr/share/ultimate-linux-suite/drivers/
├── realtek-r8152/      # r8152 driver source
├── realtek-r8821cu/    # r8821cu driver source
├── broadcom/           # Broadcom firmware/drivers
├── nvidia/             # NVIDIA driver packages
├── amd/                # AMD driver packages
└── intel/              # Intel driver packages
```

### Using the Driver Vault

1. Download driver sources when online
2. Place in appropriate directory under `drivers/`
3. Use the Driver Manager menu to install offline

### Populating the Vault

```bash
# Example: Download r8821cu driver
cd /usr/share/ultimate-linux-suite/drivers/realtek-r8821cu/
git clone https://github.com/morrownr/8821cu-20210916 .
```

## Troubleshooting

### Driver Not Loading

```bash
# Check for errors in kernel log
dmesg | grep -i error

# Check module info
modinfo <driver_name>

# Force load with verbose output
sudo modprobe -v <driver_name>
```

### DKMS Build Fails

```bash
# Ensure kernel headers are installed
sudo apt install linux-headers-$(uname -r)  # Debian/Ubuntu
sudo dnf install kernel-devel               # Fedora
sudo pacman -S linux-headers                # Arch

# Rebuild modules
sudo dkms autoinstall

# Check build logs
cat /var/lib/dkms/<module>/<version>/build/make.log
```

### WiFi Not Working After Driver Install

```bash
# Restart NetworkManager
sudo systemctl restart NetworkManager

# Check interface status
ip link show

# Bring interface up
sudo ip link set wlan0 up

# Scan for networks
nmcli device wifi list
```

### Module Conflicts

Some drivers conflict with each other. The installer automatically blacklists conflicting modules.

Check current blacklist:

```bash
cat /etc/modprobe.d/*.conf | grep blacklist
```

Common Broadcom conflicts (auto-blacklisted):

- b43, b43legacy, ssb, bcm43xx, brcmsmac

## Safety Notes

1. **GPU Drivers**: Always have a recovery plan before changing GPU drivers
2. **Kernel Updates**: DKMS rebuilds automatically, but verify after updates
3. **Backup**: Use the backup feature before major driver changes
4. **Testing**: Test driver changes with a reboot before relying on them
5. **Recovery**: Keep a live USB ready for emergencies

## Quick Reference

| Task | Menu Path |
|------|-----------|
| Scan hardware | Driver Manager > Scan Hardware |
| Install Realtek | Driver Manager > Realtek Drivers |
| Install Broadcom | Driver Manager > Broadcom WiFi |
| GPU guidance | Driver Manager > GPU Drivers |
| Rebuild DKMS | Driver Manager > DKMS Management |
