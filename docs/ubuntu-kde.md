# Ubuntu KDE Plan

Ubuntu is the second distro target.

## Why Ubuntu Second

- Ubuntu publishes generic ARM64 desktop and server images.
- Ubuntu ARM64 desktop images are available, but Surface Pro X still needs
  custom kernel, firmware, bootloader, and service handling.
- KDE Plasma can be layered through `kubuntu-desktop` or a smaller Plasma
  package set.

## Base Image Choices

Initial choices:

- Ubuntu ARM64 desktop image for desktop validation.
- Ubuntu ARM64 server image for simpler QEMU and package validation.

KDE package choices:

- `kubuntu-desktop` for a complete experience.
- smaller Plasma package set for faster image iteration.

## Packages To Build

Kernel packages:

- `linux-image-surface-pro-x`
- `linux-modules-surface-pro-x`
- `linux-headers-surface-pro-x`

Support packages:

- `surface-pro-x-boot`
- `surface-pro-x-firmware-helper`
- `surface-pro-x-qcom-services`
- `rmtfs-dummy` or equivalent service override

## Image Customization

Ubuntu image build should:

1. Start from an ARM64 Ubuntu image.
2. Add the local Surface Pro X APT repository.
3. Install custom kernel packages.
4. Install firmware helper package.
5. Install Qualcomm service package.
6. Install KDE Plasma packages if using server base.
7. Write GRUB AArch64 boot files.
8. Add Surface Pro X boot entry with DTB.
9. Enable development SSH for early images.
10. Add image manifest.

## Validation

QEMU validation:

- boots to systemd
- APT package dependencies resolve
- kernel package postinstall succeeds
- initramfs generation succeeds
- SSH works
- SDDM is enabled if KDE is installed

Hardware validation:

- USB boot
- display
- input
- NVMe
- WiFi/Bluetooth
- Plasma session

## Open Questions

- Whether to base on Ubuntu desktop ARM64 or server ARM64 plus KDE packages.
- Whether to package with DKMS-style helpers for any userspace-adjacent modules.
- How much Secure Boot support to implement in Ubuntu before hardware testing.
