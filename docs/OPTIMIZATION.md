# System Optimization Guide

Ultimate Linux Suite provides comprehensive system optimization capabilities that automatically tune your Linux system based on hardware detection and usage profiles.

## Overview

The optimization engine analyzes your hardware and applies appropriate kernel parameters, I/O schedulers, and system settings to maximize performance while maintaining stability.

## Optimization Profiles

### Auto Mode
Automatically detects your hardware and applies the most suitable optimizations:
- Detects CPU vendor (Intel/AMD) and applies appropriate settings
- Identifies storage type (SSD/NVMe/HDD) and sets optimal I/O schedulers
- Adjusts memory management based on available RAM
- Configures power settings for laptops vs desktops

### Desktop Profile
Optimized for interactive desktop use:
- Low-latency I/O scheduling
- Balanced swappiness (10-30)
- Responsive process scheduling
- Memory caching tuned for applications

### Server Profile
Optimized for server workloads:
- High-throughput I/O scheduling
- Conservative swappiness (1-10)
- Background process prioritization
- Large file caching enabled

### Laptop Profile
Optimized for battery life:
- Power-saving I/O schedulers
- Aggressive write-back caching
- CPU frequency scaling for power saving
- Display power management

### Gaming Profile
Optimized for gaming performance:
- Minimal latency I/O scheduling
- Very low swappiness (1)
- Real-time process prioritization support
- Memory mapped for large game files

### VM (Virtual Machine) Profile
Optimized for virtualized environments:
- Balloon driver friendly settings
- KSM (Kernel Same-page Merging) enabled
- Paravirtualized I/O support
- Reduced memory pressure

## Sysctl Parameters

The optimization engine manages the following kernel parameters:

### Virtual Memory
```
vm.swappiness              # Swap tendency (1-100)
vm.vfs_cache_pressure      # File cache reclaim
vm.dirty_ratio             # Max dirty memory before blocking
vm.dirty_background_ratio  # Background writeback threshold
vm.dirty_expire_centisecs  # Dirty page expiration
```

### Network
```
net.core.rmem_max          # Max receive buffer
net.core.wmem_max          # Max send buffer
net.core.netdev_max_backlog # Network queue length
net.ipv4.tcp_fastopen      # TCP Fast Open
```

### Kernel
```
kernel.sched_migration_cost_ns  # CPU migration cost
fs.file-max                     # Max open files
fs.inotify.max_user_watches     # File watch limit
```

## I/O Schedulers

The suite selects optimal I/O schedulers based on storage type:

| Storage Type | Recommended Scheduler | Rationale |
|-------------|----------------------|-----------|
| NVMe SSD    | none/mq-deadline     | Minimal overhead for fast storage |
| SATA SSD    | mq-deadline          | Balance of latency and throughput |
| HDD         | bfq                  | Fair queuing for rotational media |
| VM Storage  | none/mq-deadline     | Minimal overhead for paravirt |

## Usage

### Interactive (TUI)
```bash
ultimate-suite
# Navigate to: System Optimization
```

### Command Line
```bash
# Auto-optimize based on hardware
ultimate-suite --optimize auto

# Apply specific profile
ultimate-suite --optimize desktop
ultimate-suite --optimize server
ultimate-suite --optimize laptop
ultimate-suite --optimize gaming
```

## Configuration Storage

Optimizations are stored in:
- `/etc/sysctl.d/99-suite-optimizations.conf` - Sysctl parameters
- Configuration backup in `~/.suite-backups/`

## Reverting Changes

To revert optimizations:
1. Navigate to Recovery > Restore System
2. Select the configuration backup
3. Reboot to apply original settings

Or manually:
```bash
sudo rm /etc/sysctl.d/99-suite-optimizations.conf
sudo sysctl --system
```

## Safety Features

- All changes are backed up before modification
- Non-destructive - only adds configuration files
- Original system files are never modified
- Easy rollback through backup/restore

## Hardware Detection

The optimization engine detects:
- **CPU**: Vendor, cores, threads, virtualization support
- **GPU**: Vendor, driver in use
- **Storage**: Type (SSD/HDD/NVMe), filesystem
- **Memory**: Total RAM, swap configuration
- **Form Factor**: Desktop, laptop, virtual machine
