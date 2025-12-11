# Driver Management Guide

Ultimate Linux Suite provides hardware detection and driver management for common devices including Realtek USB network adapters, Broadcom WiFi, and GPU guidance.

## Overview

The driver management system:
- Detects hardware requiring drivers
- Manages DKMS kernel modules
- Provides a driver vault for offline installation
- Offers safe GPU driver guidance (non-aggressive)

## Supported Hardware

### Realtek r8152 USB Ethernet
USB Ethernet adapters using the RTL8152/8153/8156 chipset:
- USB Vendor ID: 0bda
- Product IDs: 8152, 8153, 8156
- Common devices: USB 2.5GbE adapters, USB-C docks

### Realtek r8821cu USB WiFi
USB WiFi adapters using the RTL8821CU chipset:
- USB Vendor ID: 0bda
- Product IDs: c811, c82c, c821, b820, c820
- Common devices: Budget USB WiFi dongles

### Broadcom WiFi
PCI/PCIe WiFi adapters from Broadcom:
- Common in laptops (especially older MacBooks)
- Requires proprietary wl driver for best support

### GPU Drivers
Guidance for NVIDIA, AMD, and Intel GPUs:
- **Non-aggressive**: Does not auto-install GPU drivers
- Provides recommendations and commands
- User must manually install after reviewing guidance

## Hardware Detection

The driver manager detects hardware via:
- `lspci` - PCI devices (GPU, WiFi cards)
- `lsusb` - USB devices (Realtek adapters)
- `lsmod` - Currently loaded kernel modules

### Detection Output
```
=== Detected Hardware ===
  gpu: NVIDIA
  broadcom_wifi: detected
  realtek_r8152: detected

=== Driver Status ===
  nvidia: nouveau_active
  broadcom_wifi: needs_driver
  realtek_r8152: installed
```

## DKMS Integration

Dynamic Kernel Module Support (DKMS) automatically rebuilds kernel modules when:
- Kernel is updated
- Module source is updated
- Manual rebuild is requested

### DKMS Commands
```bash
# Install DKMS
sudo apt install dkms  # Debian/Ubuntu
sudo dnf install dkms  # Fedora
sudo pacman -S dkms    # Arch

# List modules
dkms status

# Rebuild all modules
dkms autoinstall
```

## Driver Installation

### Realtek r8152 (USB Ethernet)

The r8152 driver is typically included in the kernel. If not working:

1. Check if driver is loaded:
   ```bash
   lsmod | grep r8152
   ```

2. Load the driver:
   ```bash
   sudo modprobe r8152
   ```

3. For newer devices, DKMS version may be needed:
   - Place driver source in `/usr/share/ultimate-linux-suite/drivers/realtek-r8152/`
   - Use the installer menu to build and install

### Realtek r8821cu (USB WiFi)

This driver is NOT included in the kernel and must be built from source:

1. Download driver source:
   ```bash
   git clone https://github.com/morrownr/8821cu-20210916
   ```

2. Place in driver vault:
   ```
   /usr/share/ultimate-linux-suite/drivers/realtek-r8821cu/
   ```

3. Use the driver installer menu to build with DKMS

4. Manual installation:
   ```bash
   cd 8821cu-20210916
   sudo ./dkms-install.sh
   ```

### Broadcom WiFi

#### Debian/Ubuntu
```bash
# Enable non-free repositories
sudo apt install broadcom-sta-dkms
sudo modprobe wl
```

#### Fedora
```bash
# Enable RPM Fusion
sudo dnf install broadcom-wl akmod-wl
sudo akmods --force
sudo modprobe wl
```

#### Arch Linux
```bash
# From AUR
yay -S broadcom-wl-dkms
sudo modprobe wl
```

### GPU Drivers

The suite provides **guidance only** for GPU drivers due to their complexity and potential system impact.

#### NVIDIA
```bash
# Ubuntu
sudo apt install nvidia-driver-xxx

# Fedora (enable RPM Fusion first)
sudo dnf install akmod-nvidia

# Arch
sudo pacman -S nvidia nvidia-utils
```

#### AMD
AMD GPUs typically work with open-source drivers (amdgpu/mesa):
```bash
# Ensure mesa and vulkan are installed
sudo apt install mesa-vulkan-drivers    # Debian/Ubuntu
sudo dnf install mesa-vulkan-drivers    # Fedora
sudo pacman -S vulkan-radeon           # Arch
```

#### Intel
Intel GPUs use the i915 driver (usually built into kernel):
```bash
# For video acceleration
sudo apt install intel-media-va-driver  # Debian/Ubuntu
sudo dnf install intel-media-driver     # Fedora
sudo pacman -S intel-media-driver       # Arch
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
2. Place in appropriate directory
3. Install offline using the driver menu

## Troubleshooting

### Driver Not Loading
```bash
# Check for errors
dmesg | grep -i error

# Check module info
modinfo <driver_name>

# Force load
sudo modprobe -v <driver_name>
```

### DKMS Build Fails
```bash
# Install kernel headers
sudo apt install linux-headers-$(uname -r)

# Rebuild
sudo dkms autoinstall

# Check DKMS logs
cat /var/lib/dkms/<module>/<version>/build/make.log
```

### WiFi Not Working After Driver Install
```bash
# Restart NetworkManager
sudo systemctl restart NetworkManager

# Check interface
ip link show

# Scan for networks
nmcli device wifi list
```

### Blacklist Conflicts
Some drivers conflict with each other. The installer automatically blacklists:
- Broadcom: b43, b43legacy, ssb, bcm43xx, brcmsmac

Check blacklist:
```bash
cat /etc/modprobe.d/*.conf | grep blacklist
```

## Safety Notes

1. **GPU Drivers**: Always have a recovery plan before changing GPU drivers
2. **Kernel Updates**: DKMS rebuilds automatically, but verify after updates
3. **Backup**: Use the backup feature before major driver changes
4. **Testing**: Test driver changes with a reboot before relying on them
