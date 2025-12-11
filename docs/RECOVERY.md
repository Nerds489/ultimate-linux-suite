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

## Accessing Recovery Tools

### Interactive Menu

```bash
sudo ultimate-linux-suite
# Navigate to: Recovery & Tools
```

Or using the alias:

```bash
sudo ultimate-suite
# Navigate to: Recovery & Tools
```

## System Health Check

Comprehensive diagnostics for system status.

### Checks Performed

| Check | Warning | Critical |
|-------|---------|----------|
| Disk Space | 80% used | 90% used |
| Memory | Low available | Out of memory |
| Swap | Not configured | Swap full |
| Services | Failed services | Critical failures |
| Packages | Broken packages | Corrupted database |
| Network | DNS issues | No connectivity |

### Running Health Check

From the menu: Recovery & Tools > System Health Check

## Package Manager Repair

Fixes common package manager issues across distributions.

### APT (Debian/Ubuntu)

Operations performed:

1. Remove stale lock files
2. Configure pending packages (`dpkg --configure -a`)
3. Fix broken dependencies (`apt --fix-broken install`)
4. Update package lists
5. Clean package cache

Manual commands:

```bash
# Remove locks
sudo rm -f /var/lib/apt/lists/lock
sudo rm -f /var/cache/apt/archives/lock
sudo rm -f /var/lib/dpkg/lock*

# Fix packages
sudo dpkg --configure -a
sudo apt --fix-broken install
sudo apt update
sudo apt clean
```

### DNF (Fedora)

Operations performed:

1. Clean all caches
2. Rebuild cache
3. Run distro-sync
4. Remove orphan packages

Manual commands:

```bash
sudo dnf clean all
sudo dnf makecache
sudo dnf distro-sync
sudo dnf autoremove
```

### Pacman (Arch)

Operations performed:

1. Remove database lock
2. Update keyring
3. Force refresh database
4. Check dependencies

Manual commands:

```bash
sudo rm -f /var/lib/pacman/db.lck
sudo pacman -Sy archlinux-keyring
sudo pacman -Syyu
sudo pacman -Dk
```

### Zypper (openSUSE)

Operations performed:

1. Clean all caches
2. Refresh repositories
3. Verify system integrity

Manual commands:

```bash
sudo zypper clean -a
sudo zypper refresh
sudo zypper verify
```

## Initramfs Regeneration

Rebuilds the initial RAM filesystem (initramfs/initrd).

### When to Regenerate

- After installing new kernel modules
- After driver changes
- After boot issues
- After filesystem changes

### Distribution-Specific Commands

| Distribution | Tool | Command |
|--------------|------|---------|
| Debian/Ubuntu | update-initramfs | `sudo update-initramfs -u -k $(uname -r)` |
| Fedora/RHEL | dracut | `sudo dracut --force` |
| Arch | mkinitcpio | `sudo mkinitcpio -P` |
| openSUSE | dracut | `sudo dracut --force` |

### From the Menu

Recovery & Tools > Repair Tools > Regenerate Initramfs

## DKMS Module Rebuild

Rebuilds all Dynamic Kernel Module Support (DKMS) modules.

### When to Rebuild

- After kernel updates
- After module compilation failures
- When modules don't load properly

### Commands

```bash
# List all DKMS modules
dkms status

# Rebuild all modules for current kernel
sudo dkms autoinstall

# Rebuild specific module
sudo dkms install <module>/<version> -k $(uname -r)
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

Regenerates `grub.cfg`:

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

1. Restart network services
2. Flush DNS cache
3. Cycle network interfaces

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

Tests performed:

- Interface status (`ip link`)
- DNS resolution (`ping google.com`)
- Internet connectivity (`ping 8.8.8.8`, `ping 1.1.1.1`)
- DNS server configuration

## Backup System

### Backup Types

| Type | Contents | Storage |
|------|----------|---------|
| Config | .bashrc, .zshrc, .config/ | ~/.suite-backups/ |
| Packages | Installed package list | ~/.suite-backups/ |
| System | /etc/ configurations | ~/.suite-backups/ |
| GRUB | Bootloader configuration | ~/.suite-backups/ |

### Creating Backups

From menu: Recovery & Tools > Backup Manager

### Backup Files

Files are named with timestamps:

- `config_backup_YYYYMMDD_HHMMSS.tar.gz`
- `packages_backup_YYYYMMDD_HHMMSS.txt`
- `system_backup_YYYYMMDD_HHMMSS.tar.gz`
- `grub_backup_YYYYMMDD_HHMMSS.tar.gz`

### Backup Location

Default: `~/.suite-backups/`

## Restore System

### From Menu

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

```bash
df -h
```

### SMART Status

Check drive health (requires smartmontools):

```bash
sudo smartctl -H /dev/sdX
```

### TRIM (SSD)

Optimize SSD storage:

```bash
sudo fstrim -av
```

## System Logs

### View Options

| Log | Command |
|-----|---------|
| System Journal | `journalctl -n 100` |
| Boot Messages | `journalctl -b` |
| Kernel Log | `dmesg \| tail -100` |
| Errors Only | `journalctl -p err -n 100` |

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
# Mount root partition
mount /dev/sdXn /mnt

# Mount required filesystems
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys

# For UEFI systems
mount /dev/sdXn /mnt/boot/efi

# Chroot
chroot /mnt
```

4. Run repairs (package manager, initramfs, GRUB)
5. Exit and reboot:

```bash
exit
umount -R /mnt
reboot
```

## Troubleshooting

### Package Manager Locked

```bash
# Debian/Ubuntu
sudo rm -f /var/lib/apt/lists/lock
sudo rm -f /var/cache/apt/archives/lock
sudo rm -f /var/lib/dpkg/lock*

# Fedora
sudo rm -f /var/run/dnf.pid

# Arch
sudo rm -f /var/lib/pacman/db.lck
```

### System Won't Boot After Kernel Update

1. Boot previous kernel from GRUB menu (hold Shift during boot)
2. Rebuild initramfs
3. Rebuild DKMS modules
4. Update GRUB configuration

### Network Not Working

1. Check interface is up: `ip link`
2. Check for IP address: `ip addr`
3. Test DNS: `ping google.com`
4. Test connectivity: `ping 8.8.8.8`
5. Restart network services

## Quick Reference

| Task | Menu Path |
|------|-----------|
| Health check | Recovery & Tools > System Health Check |
| Fix packages | Recovery & Tools > Repair Tools > Package Manager |
| Rebuild initramfs | Recovery & Tools > Repair Tools > Regenerate Initramfs |
| GRUB tools | Recovery & Tools > Repair Tools > Bootloader |
| Network repair | Recovery & Tools > Repair Tools > Network |
| Create backup | Recovery & Tools > Backup Manager |
| Restore backup | Recovery & Tools > Restore System |
