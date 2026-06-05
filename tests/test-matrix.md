# Test Matrix

## Image Tests

| Test | Arch | Fedora | Ubuntu | Notes |
| --- | --- | --- | --- | --- |
| Build base image | pass | blocked | pending | Fedora blocked as active path; Ubuntu not started |
| Install AArch64 GRUB | pass | pass | pending | Uses `grub-image-aarch64` |
| Install local kernel image | pass | pass | pending | Current local kernel is `6.18.3+` |
| Install local modules | pass | pass | pending | Arch modules staged under `/usr/lib/modules/6.18.3+` |
| Install Surface Pro X DTB | pass | pass | pending | `sc8180x-surface-pro-x.dtb` |
| Generate matching initramfs | pass | fail | pending | Fedora stock/live initramfs mismatched the hardware path |
| Add diagnostic initramfs hooks | pass | na | pending | `spxdebug`, `spxudev` |
| Add GRUB diagnostic menu | pass | pass | pending | Arch currently defaults to post-udev shell |
| QEMU generic boot smoke | partial | partial | pending | QEMU does not emulate SPX hardware |

## Hardware Boot Tests

| Test | Arch | Fedora | Ubuntu | Notes |
| --- | --- | --- | --- | --- |
| USB boot to GRUB | pass | pass | pending | Real device |
| Kernel starts | pass | pass | pending | Arch DTB path prints Surface Pro X model |
| DTB boot visible console | pass | partial | pending | Some DTB entries previously black-screened |
| ACPI boot visible console | partial | partial | pending | ACPI hits GENI/I2C issues without mitigations |
| I2C/GENI panic avoided | pass | fail | pending | Local mitigation plus DTB-first path |
| Initramfs starts | pass | fail | pending | Arch reaches `/init` |
| xHCI controller starts | pass | pass | pending | Seen in hardware logs |
| USB hubs detected | pass | pass | pending | Seen in hardware logs |
| UAS/usb-storage registered | pass | pass | pending | Seen in hardware logs |
| USB root block device appears | fail | fail | pending | Active blocker |
| Root filesystem mounts | fail | fail | pending | Waiting on USB root discovery |
| Login shell reached | blocked | fail | pending | Blocked by root mount |
| Logs collected from Linux | blocked | blocked | pending | Need mounted root or serial/net path |
| Type Cover keyboard | blocked | blocked | pending | Later after boot |
| Type Cover touchpad | blocked | blocked | pending | Later after boot |
| Battery status | blocked | blocked | pending | Later after boot |
| Charger status | blocked | blocked | pending | Later after boot |
| Thermal sensors | blocked | blocked | pending | Later after boot |
| NVMe detection | blocked | blocked | pending | Do not write internally yet |
| WiFi scan | blocked | blocked | pending | Needs firmware/services after boot |
| Bluetooth controller | blocked | blocked | pending | Needs firmware/services after boot |
| Plasma login | blocked | blocked | pending | Desktop is not current milestone |
| GPU acceleration | blocked | blocked | pending | Adreno/MSM later |
| Touch and pen | blocked | blocked | pending | Later milestone |
| Suspend/resume | blocked | blocked | pending | Later milestone |
| Audio | blocked | blocked | pending | Later milestone |
| Cameras | blocked | blocked | pending | Later milestone |
| LTE modem | blocked | blocked | pending | Later milestone |
| External display | blocked | blocked | pending | Later milestone |

## Result States

- `pending`: not tested yet
- `pass`: meets pass criteria
- `fail`: tested and failed
- `blocked`: cannot test until another dependency is solved
- `na`: not applicable

## Required Report Fields

Every hardware test result needs:

- image build ID
- kernel commit
- distro and version
- device model
- firmware version
- boot target
- pass/fail result
- logs or reason logs were unavailable
