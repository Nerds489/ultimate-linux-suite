# System Optimization Guide

Ultimate Linux Suite provides comprehensive system optimization capabilities that automatically tune your Linux system based on hardware detection and usage profiles.

## Overview

The optimization engine analyzes your hardware and applies appropriate kernel parameters, I/O schedulers, and system settings to maximize performance while maintaining stability.

## Accessing Optimization

### Interactive Menu

```bash
sudo ultimate-linux-suite
# Navigate to: System Optimization
```

Or using the alias:

```bash
sudo ultimate-suite
# Navigate to: System Optimization
```

## Optimization Profiles

### Auto Mode

Automatically detects your hardware and applies the most suitable optimizations:

- Detects CPU vendor (Intel/AMD) and applies appropriate settings
- Identifies storage type (SSD/NVMe/HDD) and sets optimal I/O schedulers
- Adjusts memory management based on available RAM
- Configures power settings for laptops vs desktops

### Desktop Profile

Optimized for interactive desktop use:

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Swappiness | 10-30 | Prefer RAM over swap for responsiveness |
| VFS Cache Pressure | 50 | Balanced file caching |
| I/O Scheduler | mq-deadline | Low-latency for SSDs |
| Governor | schedutil | Balanced power/performance |

### Server Profile

Optimized for server workloads:

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Swappiness | 1-10 | Minimize swap usage |
| VFS Cache Pressure | 100 | Aggressive file caching |
| I/O Scheduler | bfq/mq-deadline | Throughput optimized |
| Governor | ondemand | Efficient CPU scaling |

### Laptop Profile

Optimized for battery life:

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Swappiness | 60 | Default behavior |
| Dirty Writeback | Extended | Reduce disk writes |
| I/O Scheduler | bfq | Power efficient |
| Governor | powersave | Maximum battery life |

### Gaming Profile

Optimized for gaming performance:

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Swappiness | 1 | Keep games in RAM |
| VFS Cache Pressure | 50 | Cache game assets |
| I/O Scheduler | none/mq-deadline | Minimal latency |
| Governor | performance | Maximum CPU power |

### VM (Virtual Machine) Profile

Optimized for virtualized environments:

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Swappiness | 30 | Balloon driver friendly |
| KSM | Enabled | Memory deduplication |
| I/O Scheduler | none | Host handles scheduling |
| Transparent Hugepages | madvise | Application controlled |

## Sysctl Parameters

The optimization engine manages the following kernel parameters:

### Virtual Memory

```ini
# Swap behavior (0-100, lower = prefer RAM)
vm.swappiness=10

# File cache reclaim pressure (0-1000)
vm.vfs_cache_pressure=50

# Maximum dirty memory before blocking writes (%)
vm.dirty_ratio=20

# Background writeback threshold (%)
vm.dirty_background_ratio=5

# Dirty page expiration time (centiseconds)
vm.dirty_expire_centisecs=3000

# Writeback interval (centiseconds)
vm.dirty_writeback_centisecs=500
```

### Network

```ini
# Maximum receive buffer size
net.core.rmem_max=16777216

# Maximum send buffer size
net.core.wmem_max=16777216

# Network queue length
net.core.netdev_max_backlog=5000

# TCP Fast Open
net.ipv4.tcp_fastopen=3

# TCP buffer sizes (min, default, max)
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
```

### Kernel

```ini
# CPU migration cost (nanoseconds)
kernel.sched_migration_cost_ns=5000000

# Maximum open files
fs.file-max=2097152

# inotify watch limit
fs.inotify.max_user_watches=524288

# inotify instance limit
fs.inotify.max_user_instances=512
```

## I/O Schedulers

The suite selects optimal I/O schedulers based on storage type:

| Storage Type | Recommended Scheduler | Rationale |
|--------------|----------------------|-----------|
| NVMe SSD | none | Minimal overhead, NVMe handles queuing |
| SATA SSD | mq-deadline | Balance of latency and throughput |
| HDD | bfq | Fair queuing for rotational media |
| VM Storage | none/mq-deadline | Let hypervisor handle scheduling |

### Checking Current Scheduler

```bash
cat /sys/block/sda/queue/scheduler
```

### Available Schedulers

Modern kernels (5.0+) typically include:
- `none` - No scheduling (best for NVMe)
- `mq-deadline` - Deadline-based multiqueue scheduler
- `bfq` - Budget Fair Queueing
- `kyber` - Low-latency multiqueue scheduler

## Configuration Storage

Optimizations are stored in:

| File | Purpose |
|------|---------|
| `/etc/sysctl.d/99-ultimate-suite.conf` | Sysctl parameters |
| `~/.config/ultimate-suite/` | User preferences |
| `~/.suite-backups/` | Configuration backups |

## Applying Optimizations

### Through the Menu

1. Launch: `sudo ultimate-linux-suite`
2. Select "System Optimization"
3. Choose "Auto Optimize" or select a specific profile
4. Review proposed changes
5. Confirm to apply

### Verify Applied Settings

```bash
# Check sysctl values
sysctl vm.swappiness
sysctl vm.vfs_cache_pressure

# Check I/O scheduler
cat /sys/block/*/queue/scheduler

# Check CPU governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
```

## Reverting Changes

### Through the Menu

1. Navigate to: Recovery & Tools > Restore System
2. Select the configuration backup
3. Confirm restoration
4. Reboot to apply original settings

### Manual Revert

```bash
# Remove optimization config
sudo rm /etc/sysctl.d/99-ultimate-suite.conf

# Reload sysctl defaults
sudo sysctl --system

# Reboot to restore I/O schedulers and governors
sudo reboot
```

## Safety Features

- **Backup Before Changes**: All original configurations are backed up
- **Non-Destructive**: Only adds configuration files, never modifies system files
- **Reversible**: Easy rollback through backup/restore
- **Conservative Defaults**: Profiles use well-tested, stable values

## Hardware Detection

The optimization engine detects:

| Component | Detection Method | Used For |
|-----------|------------------|----------|
| CPU Vendor | `/proc/cpuinfo` | Governor selection |
| CPU Cores | `nproc` | Thread optimization |
| GPU | `lspci` | Gaming profile hints |
| Storage Type | `/sys/block/*/rotational` | I/O scheduler selection |
| Total RAM | `/proc/meminfo` | Swappiness tuning |
| Form Factor | DMI/battery | Profile suggestions |

## Best Practices

1. **Start with Auto**: Let the suite detect optimal settings first
2. **Test Before Committing**: Verify system stability after changes
3. **One Profile at a Time**: Don't stack multiple profiles
4. **Backup First**: Always have a recovery option
5. **Monitor After Changes**: Watch for performance regressions

## Troubleshooting

### Settings Not Applied After Reboot

Check if the sysctl configuration is loaded:

```bash
ls -la /etc/sysctl.d/
sudo sysctl --system
```

### High Swap Usage Despite Low Swappiness

Check memory pressure:

```bash
free -h
cat /proc/meminfo | grep -i swap
```

### I/O Scheduler Not Changing

Some storage devices don't support scheduler changes:

```bash
# Check available schedulers
cat /sys/block/sda/queue/scheduler

# NVMe devices often only support 'none'
cat /sys/block/nvme0n1/queue/scheduler
```

## Further Reading

- [Kernel Documentation - Sysctl](https://www.kernel.org/doc/Documentation/sysctl/)
- [Arch Wiki - Improving Performance](https://wiki.archlinux.org/title/Improving_performance)
- [Red Hat Performance Tuning Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/monitoring_and_managing_system_status_and_performance/)
