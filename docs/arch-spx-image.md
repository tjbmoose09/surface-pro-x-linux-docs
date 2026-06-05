# Arch Linux ARM Surface Pro X Image

This is the current primary boot path for Surface Pro X Model 1876
(Microsoft SQ1/SQ2, Qualcomm SC8180X).

Fedora live media is no longer the first test target. Its live root uses
dracut, EROFS/squashfs, device-mapper live overlays, and ISO rebuild logic.
Those layers made it hard to separate an actual hardware-description failure
from a live-media root-mount failure.

The Arch path uses the linux-surface `aarch64-arch-mkimg` reference and builds
a normal GPT disk image:

- partition 1: FAT EFI system partition
- partition 2: ext4 Arch Linux ARM root filesystem
- `BOOTAA64.EFI`: AArch64 GRUB from `grub-image-aarch64`
- kernel: locally built `spx/v6.18` image
- DTB: `sc8180x-surface-pro-x.dtb`
- modules: locally built `6.18.3+`
- firmware: linux-surface `aarch64-firmware`

## Why DTB First

The Fedora ACPI tests consistently failed in `i2c_qcom_geni`:

- first at `clk_get_rate()` with an invalid ACPI clock pointer
- then at `geni_se_get_qup_hw_version()` because the ACPI-created GENI device
  had no QUP wrapper parent data

That points to an incomplete ACPI hardware graph for Linux Qualcomm drivers.
The SC8180X device tree describes the QUP/GENI parent-child hierarchy, clocks,
interconnects, and resources in the form the kernel drivers expect.

The first GRUB entry therefore uses:

```text
devicetree /boot/dtb/linux-surface/qcom/sc8180x-surface-pro-x.dtb
linux /boot/vmlinuz-linux-surface-spx root=UUID=... rw rootwait rootdelay=15 \
  efi=novamap clk_ignore_unused earlycon=efifb console=tty0 \
  loglevel=8 ignore_loglevel keep_bootcon no_console_suspend panic=-1 \
  nomodeset usbcore.autosuspend=-1 spxdiag=1 spxbreak=postudev
initrd /boot/initramfs-spx.img
```

The current default is an initramfs diagnostic entry, not direct root. Direct
root proved that the kernel can start, but it did not show enough information
when the USB root device failed to appear.

## Current Blocker

The physical Surface Pro X now reaches the Arch initramfs. The active failure is
root-device discovery:

```text
Waiting for root device UUID=...
Waiting for root device PARTUUID=...
```

Boot logs show xHCI host controllers, USB hubs, `uas`, and `usb-storage`, but
the ext4 root partition is not yet reliably visible as a block device.

The current initramfs therefore includes two local hooks:

- `spxdebug`: prints command line, loaded modules, root candidates, and filtered
  USB/storage `dmesg`
- `spxudev`: starts udev, triggers subsystem/device events, and uses bounded
  `udevadm settle --timeout=10`

The debug goal is to determine whether `/dev/sd*` appears after USB/hub
initialization.

## Build

Build the local kernel and staged artifacts first:

```bash
scripts/build-kernel.sh
scripts/install-kernel-artifacts.sh
```

Build the Arch image:

```bash
sudo scripts/build-arch-spx-image.sh --out build/artifacts/images/arch-spx.img
```

If the upstream image already exists and only the local kernel/DTB/GRUB payload
needs to be refreshed:

```bash
sudo scripts/build-arch-spx-image.sh \
  --skip-fetch --skip-build \
  --out build/artifacts/images/arch-spx.img
```

## Temporary Builder Workarounds

The wrapper intentionally patches only the temporary container build context:

- changes the Docker base image to `docker.io/archlinux/archlinux`
- disables pacman Landlock sandboxing inside the generated rootfs because this
  host/container path does not support it
- removes the `qcom-wifi` profile module for now because upstream
  `rmtfs-dummy` currently fails to apply its patch against current
  `linux-msm/rmtfs`
- trims the package list to first-boot essentials
- adds extra ext4 root partition slack

The source repos under `build/src` are not edited by those workarounds.

## Test Order

Use the GRUB menu in this order:

1. `Arch SPX - DTB post-udev diagnostic shell`
2. `Arch SPX - DTB bounded-udev root UUID`
3. `Arch SPX - DTB bounded-udev root PARTUUID`
4. `Arch SPX - DTB pre-udev diagnostic shell`
5. `Arch SPX - DTB direct root UUID no initrd`
6. `Arch SPX - ACPI bounded-udev I2C blacklisted`

The expected first useful result is entry 1. It should print diagnostics and
drop to an initramfs shell. If `/dev/sd*` exists there, root resolution/timing is
the next fix. If no `/dev/sd*` exists, the next work is USB/DWC3/Type-C storage
enumeration.

At the diagnostic shell:

```sh
ls -l /dev/sd* /dev/disk/by-uuid /dev/disk/by-partuuid
dmesg | grep -Ei 'usb|xhci|dwc3|uas|storage|scsi|sd[a-z]|root|partuuid' | tail -120
```

Successful boot logs should appear under:

```text
/var/log/spx/boot.txt
/var/log/spx/dmesg.txt
/var/log/spx/journal.txt
```

Default Arch Linux ARM credentials remain:

```text
root/root
alarm/alarm
```
