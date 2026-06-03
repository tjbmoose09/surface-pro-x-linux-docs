# Upstream Map

This document maps the upstream repositories and the role each one plays in the
Surface Pro X Linux process.

## Device Status

Repository:

```text
https://github.com/linux-surface/surface-pro-x
```

Purpose:

- Tracks Surface Pro X-specific issues.
- Provides the wiki pages for basic setup, WiFi, Bluetooth, GPU, touch, and pen.
- Separates Surface Pro X work from the normal x86 Surface device path.

Key notes from the wiki:

- Patched images are easier than generic installers.
- ACPI boot is limited and mostly useful for basic bootstrapping.
- Device-tree boot is the long-term path for full hardware enablement.
- Required kernel args include `efi=novamap` and `clk_ignore_unused`.
- WiFi needs firmware plus Qualcomm userspace services.

## Main linux-surface Project

Repository:

```text
https://github.com/linux-surface/linux-surface
```

Purpose:

- Documents the broader linux-surface project.
- Provides the normal Surface device support and package repository model.
- Useful for packaging conventions and project expectations.

Important distinction:

Most supported devices in `linux-surface/linux-surface` are x86 Surface devices.
The Surface Pro X is ARM64 and needs separate kernel, firmware, bootloader, and
image handling.

## Kernel

Repository:

```text
https://github.com/linux-surface/kernel
```

Purpose:

- Contains Surface Pro X kernel branches under `spx/*`.
- Current package references point at a 6.18.3 Surface Pro X kernel commit.

Expected kernel deliverables:

- `Image`
- modules
- module metadata
- DTBs
- headers
- config fragments
- changelog and source commit pinning

## AArch64 Firmware

Repository:

```text
https://github.com/linux-surface/aarch64-firmware
```

Purpose:

- Provides firmware layout and helper scripts.
- Extracts firmware from a Windows installation or Surface recovery image.
- Contains some helper files used for Qualcomm subsystems.

Important legal note:

Some firmware is proprietary and may not have clear redistribution rights. The
safe process is to document how device owners extract firmware from their own
Windows recovery image.

## AArch64 Packages

Repository:

```text
https://github.com/linux-surface/aarch64-packages
```

Purpose:

- Provides Arch AArch64 reference packages.
- Shows how the kernel, firmware, `rmtfs-dummy`, and signed shim were packaged.

Useful references:

- `linux-surface/PKGBUILD`
- `linux-firmware/PKGBUILD`
- `rmtfs-dummy/PKGBUILD`
- `shim-aarch64-signed/PKGBUILD`

We should translate this structure into Fedora RPM and Ubuntu DEB packaging.

## AArch64 Arch Image Builder

Repository:

```text
https://github.com/linux-surface/aarch64-arch-mkimg
```

Purpose:

- Provides a reference image-builder workflow.
- Supports x86 hosts through Docker, `binfmt_misc`, and `qemu-user-static`.
- Defines default and persistent image profiles.

We should reuse the process ideas, not the Arch-specific package layer.

## AArch64 GRUB Image

Repository:

```text
https://github.com/linux-surface/grub-image-aarch64
```

Purpose:

- Builds a known-good AArch64 GRUB image for Surface Pro X.
- Produces `bootaa64.efi`.

This should become part of our boot artifact build.

## External Service Dependencies

WiFi and Qualcomm remote processor support require userspace services:

- `qrtr`
- `pd-mapper`
- `tqftpserv`
- `rmtfs`, patched or configured for dummy EFS files

The Arch package reference includes `rmtfs-dummy`, which redirects modem file
lookups to `/var/lib/rmtfs`.
