Broadcom Wireless Driver
=========================

This directory is for Broadcom wireless (WiFi) drivers.

Expected contents:
- DKMS source packages
- Firmware files
- Installation scripts

Supported driver types:
- b43 (open source, requires firmware extraction)
- brcmfmac (open source, for newer chips)
- wl/broadcom-sta (proprietary, for older chips)

Common Broadcom chipsets:
- BCM4311, BCM4312, BCM4313
- BCM4321, BCM4322
- BCM4331, BCM4352, BCM4360
- BCM43142, BCM43224, BCM43225

Note: Broadcom drivers often require proprietary firmware.
The driver module will guide you through the appropriate
installation method for your specific hardware.
