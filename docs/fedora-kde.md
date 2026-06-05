# Fedora KDE Plan

Fedora is a future distro target, not the active first-boot target.

The project initially tried Fedora first because Fedora publishes strong ARM64
images and has good RPM infrastructure. Hardware testing showed that Fedora
live media adds too much live-boot complexity for first bring-up on Surface Pro
X. The active target is now Arch Linux ARM until USB root boot is solved.

## Why Fedora Still Matters

- Fedora KDE publishes AArch64 KDE Plasma images.
- Fedora has strong ARM64 packaging infrastructure.
- Fedora uses modern kernels and firmware packaging.
- RPM packaging is a good fit for kernel subpackages.

## Why Fedora Was Deferred

Observed failures on physical Surface Pro X:

- dracut emergency shell
- `/dev/mapper/live-rw` timeout
- `/dev/disk/by-label/Fedora-US-Live-44` not found
- ACPI `i2c_qcom_geni` kernel panic
- black screen or stalled spinner on several live entries

Determination:

- Fedora live media is not the best place to debug the hardware description.
- The live overlay stack obscures whether the failure is USB storage, dracut,
  kernel driver behavior, or ISO assembly.
- Fedora should resume after the simpler Arch GPT/ext4 USB image can mount its
  root filesystem on the tablet.

## Base Image Choices

Initial choices:

- Fedora KDE AArch64 raw image for image customization.
- Fedora Server AArch64 QEMU image for fast QEMU tests.

Later choices:

- Custom Fedora image compose.
- COPR package repository for kernel and Surface Pro X packages.

## Packages To Build

Kernel packages:

- `kernel-surface-pro-x`
- `kernel-surface-pro-x-core`
- `kernel-surface-pro-x-modules`
- `kernel-surface-pro-x-devel`

Support packages:

- `surface-pro-x-release`
- `surface-pro-x-boot`
- `surface-pro-x-firmware-helper`
- `surface-pro-x-qcom-services`
- `rmtfs-dummy` or equivalent service override

## Image Customization

Fedora image build should:

1. Start from an AArch64 Fedora KDE or Fedora base image.
2. Add the Surface Pro X package repository.
3. Install the Surface Pro X kernel package.
4. Install firmware helper package.
5. Install Qualcomm service package.
6. Install or verify KDE Plasma and SDDM.
7. Write GRUB AArch64 boot files.
8. Add Surface Pro X boot entry with DTB.
9. Enable development SSH for early images.
10. Write `/etc/os-release` marker or image manifest.

## Validation

QEMU validation:

- boots to systemd
- packages are installed
- SSH works
- SDDM service is enabled

Hardware validation:

- USB boot
- display stays visible
- Type Cover works
- NVMe detection
- WiFi after service startup
- Plasma session starts

## Open Questions

- Whether to package through COPR or local RPM repository first.
- Whether Fedora image customization should use `livemedia-creator`,
  `osbuild`, or a simpler loopback image modifier for early work.
- Whether to make the first Fedora image installable or development-only.
- Whether to avoid live media entirely and instead build a normal ext4 root
  image once the Arch path is understood.
