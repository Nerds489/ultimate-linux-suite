# Recovery & Repair Guide

Ultimate Linux Suite provides comprehensive system recovery, repair tools, and backup/restore functionality.

## Overview

The recovery module includes:
- System health checks
- Package manager repair
- Initramfs regeneration
- DKMS module rebuilding
- Bootloader (GRUB) management
- Network repair
- Backup and restore

## System Health Check

Comprehensive diagnostics for system status:

### Checks Performed
- **Disk Space**: Warning at 80%, critical at 90%
- **Memory**: Available memory percentage
- **Swap**: Configuration status
- **Failed Services**: Systemd service status
- **Package Manager**: Broken packages detection
- **Network**: Internet connectivity test

### Running Health Check
```bash
# Interactive
ultimate-suite
# Navigate to: Recovery & Tools > System Health Check

# CLI
ultimate-suite --recovery health
```

## Package Manager Repair

Fixes common package manager issues:

### APT (Debian/Ubuntu)
- Removes lock files
- Configures pending packages (`dpkg --configure -a`)
- Fixes broken dependencies (`apt --fix-broken install`)
- Updates package lists
- Cleans cache

### DNF (Fedora)
- Cleans all caches
- Rebuilds cache
- Runs distro-sync
- Removes orphan packages

### Pacman (Arch)
- Removes database lock
- Updates keyring
- Force refreshes package database
- Checks for dependency issues

### Zypper (openSUSE)
- Cleans all caches
- Refreshes repositories
- Verifies system integrity

## Initramfs Regeneration

Rebuilds the initial RAM filesystem (initramfs/initrd):

### When to Regenerate
- After installing new kernel modules
- After driver changes
- After boot issues
- After filesystem changes

### Distribution-Specific Tools
| Distribution | Tool | Command |
|--------------|------|---------|
| Debian/Ubuntu | update-initramfs | `update-initramfs -u -k $(uname -r)` |
| Fedora/RHEL | dracut | `dracut --force` |
| Arch | mkinitcpio | `mkinitcpio -P` |

### Using the Recovery Menu
```bash
# Navigate to: Recovery & Tools > Repair Tools > Regenerate Initramfs
```

## DKMS Module Rebuild

Rebuilds all Dynamic Kernel Module Support (DKMS) modules:

### When to Rebuild
- After kernel updates
- After module compilation failures
- When modules don't load properly

### Commands
```bash
# List all DKMS modules
dkms status

# Rebuild all modules
dkms autoinstall

# Rebuild specific module
dkms install <module>/<version> -k $(uname -r)
```

## Bootloader (GRUB) Management

### Check Status
Displays:
- Boot mode (UEFI/BIOS)
- GRUB configuration location
- Default boot entry
- Timeout setting
- Boot device

### Update Configuration
Regenerates `grub.cfg` from `/etc/default/grub`:
```bash
# Debian/Ubuntu
sudo update-grub

# Fedora
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# Arch
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Reinstall GRUB
**Warning**: Can make system unbootable if done incorrectly!

#### BIOS Systems
```bash
sudo grub-install /dev/sdX
sudo update-grub
```

#### UEFI Systems
```bash
sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
sudo update-grub
```

## Network Repair

### Full Network Repair
Performs:
1. Restarts network services (NetworkManager/systemd-networkd)
2. Flushes DNS cache
3. Cycles network interfaces

### Individual Operations

#### Restart Network Service
```bash
sudo systemctl restart NetworkManager
# or
sudo systemctl restart systemd-networkd
```

#### Flush DNS Cache
```bash
# systemd-resolved
sudo resolvectl flush-caches

# nscd
sudo nscd -i hosts

# dnsmasq
sudo systemctl restart dnsmasq
```

### Connectivity Test
Checks:
- Interface status
- DNS resolution (google.com)
- Internet connectivity (8.8.8.8, 1.1.1.1)
- Configured DNS servers

## Backup System

### Backup Types

| Type | Contents | Location |
|------|----------|----------|
| Config | .bashrc, .zshrc, .config/ | ~/.suite-backups/ |
| Packages | Installed package list | ~/.suite-backups/ |
| System | /etc/ configurations | ~/.suite-backups/ |
| GRUB | Bootloader config | ~/.suite-backups/ |

### Creating Backups
```bash
# Interactive
# Navigate to: Recovery & Tools > Backup Manager

# CLI
ultimate-suite --recovery backup config
ultimate-suite --recovery backup packages
```

### Backup Location
Default: `~/.suite-backups/`

Files are named:
- `config_backup_YYYYMMDD_HHMMSS.tar.gz`
- `packages_backup_YYYYMMDD_HHMMSS.txt`
- `system_backup_YYYYMMDD_HHMMSS.tar.gz`
- `grub_backup_YYYYMMDD_HHMMSS.tar.gz`

## Restore System

### Restoring from Backup
1. Navigate to: Recovery & Tools > Restore System
2. Select backup file
3. Confirm restoration
4. Reboot if necessary

### Manual Restoration

#### Configuration Backup
```bash
cd ~
tar -xzf ~/.suite-backups/config_backup_*.tar.gz
```

#### Package List (Debian/Ubuntu)
```bash
sudo dpkg --set-selections < packages_backup.txt
sudo apt-get dselect-upgrade
```

#### Package List (Fedora)
```bash
sudo dnf install $(cat packages_backup.txt)
```

#### Package List (Arch)
```bash
sudo pacman -S --needed $(cat packages_backup.txt | awk '{print $1}')
```

## Disk Utilities

### Disk Usage
Shows filesystem usage with df:
```bash
df -h
```

### SMART Status
Checks drive health (requires smartmontools):
```bash
sudo smartctl -H /dev/sdX
```

### TRIM (SSD)
Optimizes SSD storage:
```bash
sudo fstrim -av
```

## System Logs

### View Options
- **System Journal**: Recent systemd journal entries
- **Boot Messages**: Current boot log
- **Kernel Log**: dmesg output
- **Recent Errors**: Priority error messages

### Commands
```bash
# Journal
journalctl -n 100

# Boot log
journalctl -b

# Kernel log
dmesg | tail -100

# Errors only
journalctl -p err -n 100
```

## Best Practices

1. **Regular Backups**: Create backups before major changes
2. **Test After Repairs**: Verify system operation after repairs
3. **Keep Recovery Media**: Have a live USB ready for emergencies
4. **Document Changes**: Note what repairs were performed
5. **Check Logs**: Review logs after issues for root cause

## Emergency Recovery

If the system won't boot:

1. Boot from live USB
2. Mount your partitions
3. Chroot into the system:
   ```bash
   mount /dev/sdXn /mnt
   mount --bind /dev /mnt/dev
   mount --bind /proc /mnt/proc
   mount --bind /sys /mnt/sys
   chroot /mnt
   ```
4. Run repairs (package manager, initramfs, GRUB)
5. Exit and reboot

## Troubleshooting

### Package Manager Locked
```bash
# Remove lock files
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock*
```

### System Won't Boot After Kernel Update
1. Boot previous kernel from GRUB menu
2. Rebuild initramfs
3. Rebuild DKMS modules
4. Update GRUB

### Network Not Working
1. Check interface is up: `ip link`
2. Check for IP address: `ip addr`
3. Test DNS: `ping google.com`
4. Test connectivity: `ping 8.8.8.8`
5. Restart network services
