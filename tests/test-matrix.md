# Test Matrix

## QEMU Tests

| Test | Fedora | Ubuntu | Notes |
| --- | --- | --- | --- |
| Image boots to systemd | pending | pending | Generic ARM64 only |
| SSH starts | pending | pending | Development images |
| Kernel package installed | pending | pending | Package validation |
| Initramfs exists | pending | pending | Boot validation |
| EFI boot files present | pending | pending | `BOOTAA64.EFI` |
| GRUB config present | pending | pending | Includes SPX entry |
| Required kernel args present | pending | pending | `efi=novamap clk_ignore_unused` |
| QCOM service units installed | pending | pending | Not hardware validated |
| KDE packages installed | pending | pending | Smoke only |
| SDDM enabled | pending | pending | Smoke only |

## Hardware Tests

| Test | Fedora | Ubuntu | Notes |
| --- | --- | --- | --- |
| USB boot to GRUB | pending | pending | Real device |
| Kernel starts | pending | pending | Real device |
| Display stays visible | pending | pending | Known risk |
| Root filesystem mounts | pending | pending | USB first |
| Logs collected | pending | pending | Required |
| Type Cover keyboard | pending | pending | SAM path |
| Type Cover touchpad | pending | pending | SAM path |
| Battery status | pending | pending | Surface driver |
| Charger status | pending | pending | Surface driver |
| Thermal sensors | pending | pending | Surface/QCOM |
| NVMe detection | pending | pending | Do not write initially |
| WiFi scan | pending | pending | Needs firmware/services |
| Bluetooth controller | pending | pending | Needs firmware fixes |
| Plasma login | pending | pending | Real usability |
| GPU acceleration | pending | pending | Adreno/MSM |
| Touch single-touch | pending | pending | SPI HID |
| Touch multitouch | pending | pending | IPTSd |
| Pen input | pending | pending | IPTSd |
| Suspend/resume | pending | pending | Later milestone |
| Audio | pending | pending | Later milestone |
| Cameras | pending | pending | Later milestone |
| LTE modem | pending | pending | Later milestone |
| External display | pending | pending | Later milestone |

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
