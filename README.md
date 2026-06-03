# Surface Pro X Linux Enablement

Documentation and build-process planning for running Linux on the Microsoft
Surface Pro X.

The Surface Pro X is not part of the normal x86 Surface bring-up path. It is an
AArch64 Qualcomm device, so the work has to combine a custom ARM64 kernel,
device-tree boot, firmware extraction, Qualcomm userspace services, distro
packaging, image generation, QEMU smoke testing, and physical-device validation.

## Goals

- Build reproducible Fedora KDE and Ubuntu KDE images for Surface Pro X.
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
├── docs/
│   ├── upstream-map.md
│   ├── build-pipeline.md
│   ├── firmware.md
│   ├── qemu-testing.md
│   ├── fedora-kde.md
│   ├── ubuntu-kde.md
│   ├── hardware-validation.md
│   └── roadmap.md
├── scripts/
│   └── README.md
├── tests/
│   └── test-matrix.md
└── artifacts/
    └── .gitkeep
```

## First Milestone

The first milestone is not a fully working tablet install. It is a repeatable
toolchain that can:

1. Build or fetch the current Surface Pro X kernel branch.
2. Produce kernel modules and DTBs.
3. Produce distro packages for Fedora and Ubuntu.
4. Assemble bootable ARM64 images with KDE Plasma.
5. Run QEMU smoke tests against those images.
6. Produce a hardware test checklist for USB boot on a real Surface Pro X.

## Current Assumptions

- Fedora is the first distro target because Fedora KDE publishes AArch64 KDE
  images.
- Ubuntu is the second distro target because Ubuntu publishes generic ARM64
  desktop and server images, and KDE Plasma can be layered through packages.
- Arch AArch64 remains the reference implementation, not the final target.
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
