# Build Pipeline

The target pipeline should be containerized and reproducible. A developer should
be able to build Fedora and Ubuntu artifacts from an x86_64 Linux host without
manually chasing package recipes.

## Target Commands

The long-term interface should look like this:

```sh
make kernel
make firmware SPX_WINDOWS_ROOT=/path/to/windows/recovery
make grub
make fedora-packages
make ubuntu-packages
make fedora-image
make ubuntu-image
make qemu-smoke
```

## Build Stages

### 1. Source Pinning

Inputs:

- Surface Pro X kernel branch or commit.
- AArch64 kernel config base.
- Surface Pro X config fragment.
- Packaging recipe revisions.
- Firmware helper revision.

Output:

- `build/manifest.json`
- `build/source-lock.md`

Every image should be traceable to exact source commits.

### 2. Kernel Build

Inputs:

- `linux-surface/kernel`
- base ARM64 distro config
- Surface Pro X config fragment
- distro override fragment

Outputs:

- `Image`
- modules
- DTBs
- headers
- kernel config
- package metadata

Required kernel config themes:

- Qualcomm SoC support
- SC8180X platform support
- QCOM SMMU/IOMMU
- QCOM clocks, regulators, interconnects, remoteproc, QRTR
- USB DWC3/QCOM
- Surface Aggregator modules
- Surface HID, battery, charger, RTC, thermal
- SPI HID for touch
- Adreno/MSM DRM stack

### 3. Firmware Assembly

Inputs:

- Windows recovery image or mounted Windows installation.
- `aarch64-firmware` helper scripts.
- upstream `linux-firmware`.

Outputs:

- extracted firmware tree
- generated WiFi `board-2.bin`
- patched WiFi `firmware-5.bin`
- Bluetooth symlink fixes
- distro package payload

Firmware must be treated as user-provided unless redistribution rights are
confirmed.

### 4. Qualcomm Userspace Services

Package or install:

- `qrtr`
- `pd-mapper`
- `tqftpserv`
- patched `rmtfs`

For early bootstrapping, `rmtfs` should point at dummy files under:

```text
/var/lib/rmtfs
```

Files:

```text
modem_fs1
modem_fs2
modem_fsc
modem_fsg
modem_tuning
```

Each dummy file is currently expected to be roughly 2 MiB and zero-filled.

### 5. Bootloader

Early phase:

- Secure Boot off.
- GRUB AArch64 `bootaa64.efi`.
- Explicit kernel, initramfs, and DTB entries.

Later phase:

- signed shim
- MOK enrollment
- signed kernel
- signed GRUB or signed UKI if the project moves to unified kernel images

Required kernel command line:

```text
efi=novamap clk_ignore_unused
```

### 6. Distro Package Layer

Fedora outputs:

- `kernel-surface-pro-x`
- `kernel-surface-pro-x-core`
- `kernel-surface-pro-x-modules`
- `kernel-surface-pro-x-devel`
- `surface-pro-x-firmware-helper`
- `surface-pro-x-qcom-services`
- `surface-pro-x-release`

Ubuntu outputs:

- `linux-image-surface-pro-x`
- `linux-modules-surface-pro-x`
- `linux-headers-surface-pro-x`
- `surface-pro-x-firmware-helper`
- `surface-pro-x-qcom-services`
- `surface-pro-x-boot`

### 7. Image Assembly

Image contents:

- EFI partition
- GRUB AArch64 loader
- kernel and initramfs
- Surface Pro X DTB
- root filesystem
- KDE Plasma desktop
- NetworkManager
- SSH for development images
- logging and diagnostic tools

Initial target:

- USB-bootable images.

Later target:

- NVMe installation flow.

## Artifact Rules

- Build artifacts should not be committed.
- Firmware extracted from Windows should not be committed.
- Logs may be committed only after removing serial numbers, MAC addresses, and
  other device identifiers.
- Every release image should include a source manifest.
