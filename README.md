# Surface Pro X Linux Bring-Up

Documentation, build tooling, and hardware-test notes for running Linux on the
Microsoft Surface Pro X.

The Surface Pro X is not part of the normal x86 Surface bring-up path. It is an
AArch64 Qualcomm device, so the work has to combine a custom ARM64 kernel,
device-tree boot, firmware extraction, Qualcomm userspace services, distro
packaging, image generation, QEMU smoke testing, and physical-device validation.

## Current Status

Status as of 2026-06-05: this is now an Arch Linux ARM hardware bring-up
project. Fedora and Ubuntu remain useful future distro targets, but Fedora live
media is no longer the active first-boot path because its dracut/live-overlay
stack made hardware failures hard to isolate.

Current progress on the physical Surface Pro X:

- AArch64 GRUB boots from USB.
- The local linux-surface `spx/v6.18` kernel boots with the Surface Pro X DTB.
- The prior ACPI `i2c_qcom_geni` kernel panic has been avoided with local
  driver changes and by preferring DTB boot.
- USB host and hub initialization now reaches xHCI, UAS, and usb-storage.
- The current blocker is root-device discovery from USB: the kernel reaches the
  initramfs, but the ext4 root partition is not reliably visible as `/dev/sd*`.
- The active test image uses a custom Arch initramfs hook, `spxudev`, to bound
  `udevadm settle` and print USB/storage diagnostics.

See `docs/bringup-log.md` for the detailed test history and `docs/arch-spx-image.md`
for the current image path.

## Goals

- Build a reproducible Arch Linux ARM USB image for early Surface Pro X
  hardware bring-up.
- Preserve Fedora and Ubuntu packaging/image notes for later distro support.
- Package the Surface Pro X kernel, modules, DTBs, initramfs hooks, firmware,
  and required Qualcomm services.
- Keep QEMU tests for fast image and boot validation.
- Keep physical Surface Pro X tests for hardware-specific validation.
- Document every firmware, bootloader, distro, and test step clearly enough that
  the process can be repeated.

## Non-Goals

- Pretending QEMU can fully emulate Surface Pro X hardware.
- Reusing the x86 linux-surface package flow without adapting it for AArch64.
- Redistributing proprietary Microsoft or Qualcomm firmware without confirming
  redistribution rights.

## Primary Upstream Sources

- Surface Pro X status and wiki:
  https://github.com/linux-surface/surface-pro-x
- Main linux-surface packaging and documentation:
  https://github.com/linux-surface/linux-surface
- Surface Pro X kernel branches:
  https://github.com/linux-surface/kernel
- AArch64 firmware helper:
  https://github.com/linux-surface/aarch64-firmware
- AArch64 package references:
  https://github.com/linux-surface/aarch64-packages
- AArch64 Arch image reference:
  https://github.com/linux-surface/aarch64-arch-mkimg
- Surface Pro X GRUB reference:
  https://github.com/linux-surface/grub-image-aarch64

## Planned Repository Layout

```text
.
├── README.md
├── config/
│   ├── project.env
│   ├── sources.env
│   └── kernel/
├── docs/
│   ├── upstream-map.md
│   ├── build-pipeline.md
│   ├── firmware.md
│   ├── qemu-testing.md
│   ├── fedora-kde.md
│   ├── ubuntu-kde.md
│   ├── hardware-validation.md
│   ├── tooling.md
│   └── roadmap.md
├── packaging/
├── containers/
├── scripts/
│   └── README.md
├── tests/
│   └── test-matrix.md
└── artifacts/
    └── .gitkeep
```

## Active Milestone

The active milestone is not a fully working tablet install. It is a repeatable
USB boot path that can:

1. Build or fetch the current Surface Pro X kernel branch.
2. Produce kernel modules and DTBs.
3. Assemble an Arch Linux ARM USB image with local kernel artifacts.
4. Boot through AArch64 GRUB on the physical Surface Pro X.
5. Reach initramfs diagnostics with useful USB/storage logs.
6. Mount the USB root filesystem and reach a login shell.

## Current Assumptions

- Arch Linux ARM is the first active test target because it gives us a plain
  GPT/ext4 root filesystem and avoids Fedora live-media overlay complexity.
- Fedora and Ubuntu are later distro targets once hardware boot is understood.
- DTB boot is preferred over ACPI for now because the Qualcomm GENI/I2C topology
  is more complete in the SC8180X device tree than in the exposed ACPI graph.
- Secure Boot is disabled for early hardware bring-up.
- Secure Boot support is a later milestone using shim, MOK, and signed kernel
  artifacts.

## Critical Boot Parameters

The Surface Pro X wiki calls out these required kernel parameters:

```text
efi=novamap
clk_ignore_unused
```

`efi=novamap` applies to ACPI and device-tree boot. `clk_ignore_unused` is
needed for device-tree boot.

## Test Boundary

QEMU can validate image structure, generic AArch64 boot, initramfs behavior,
package installation, service startup, and desktop startup.

QEMU cannot validate Surface Pro X hardware behavior without a custom machine
model. The real tablet is required for SAM, Type Cover, battery, thermal, NVMe,
Adreno GPU, WiFi/Bluetooth firmware, touch, pen, suspend, LTE, cameras, and
external display tests.

## Starter Tooling

The repository includes first-pass tools for starting the work:

```sh
make check-host
make fetch-upstreams
make kernel
make kernel-install-artifacts
SPX_WINDOWS_ROOT=/path/to/windows-root make firmware
make grub
make arch-spx-image
sudo scripts/build-arch-spx-image.sh --write /dev/sdX
```

See `docs/tooling.md` for the command guide.
