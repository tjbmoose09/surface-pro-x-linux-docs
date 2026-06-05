# Surface Pro X Bring-Up Log

This log tracks the current hardware bring-up work for Surface Pro X Model 1876
(Microsoft SQ1/SQ2, Qualcomm SC8180X). It is intentionally practical: what was
tested, what failed, what changed, and what the next test should prove.

## Device Under Test

- Device: Microsoft Surface Pro X Model 1876
- SoC: Microsoft SQ1/SQ2, Qualcomm SC8180X family
- Firmware observed in boot logs: Surface Pro X BIOS `7.703.140` dated
  `02/02/2024`
- Boot media: USB-C flash drive
- Secure Boot: disabled for unsigned early bring-up

## Current Direction

The project pivoted from Fedora live media to Arch Linux ARM.

Reason: Fedora live images add dracut, live root labels, EROFS/squashfs,
device-mapper overlays, and ISO remastering. Those layers made it hard to tell
whether a failure was a Surface Pro X hardware-description problem or a live
media assembly problem.

Arch Linux ARM is now the active path because it gives us:

- a normal GPT disk image
- FAT ESP plus ext4 root
- AArch64 GRUB from `linux-surface/grub-image-aarch64`
- local kernel, modules, and DTB installed directly into the image
- a smaller initramfs that we can patch and inspect quickly

Fedora and Ubuntu are kept as future distro targets after USB root boot is
reliable.

## Upstreams Used

- `linux-surface/surface-pro-x`: status and historical notes
- `linux-surface/linux-surface`: packaging and project reference
- `linux-surface/kernel`: active SPX kernel branch
- `linux-surface/aarch64-arch-mkimg`: Arch image base
- `linux-surface/grub-image-aarch64`: AArch64 GRUB image
- `linux-surface/aarch64-firmware`: firmware layout reference
- Linux mainline `drivers/i2c/busses/i2c-qcom-geni.c`: compared against local
  GENI/I2C behavior

## Kernel and Image State

Local kernel source:

```text
build/src/kernel
```

Kernel branch:

```text
linux-surface/kernel spx/v6.18
```

Current built release:

```text
6.18.3+
```

Staged artifacts:

```text
build/artifacts/kernel/Image
build/artifacts/kernel/kernel.release
build/artifacts/kernel/modules/lib/modules/6.18.3+/
build/artifacts/kernel/dtbs/qcom/sc8180x-surface-pro-x.dtb
```

Important kernel config facts:

```text
CONFIG_DEVTMPFS=y
CONFIG_DEVTMPFS_MOUNT=y
CONFIG_SCSI=y
CONFIG_BLK_DEV_SD=y
CONFIG_USB_STORAGE=y
CONFIG_USB_UAS=y
CONFIG_EXT4_FS=y
CONFIG_QCOM_GENI_SE=y
```

`sd_mod` and related storage support are built in, so the current root-device
failure is not simply a missing `sd_mod.ko`.

## Local Kernel Findings

ACPI boot exposed a failure path in `i2c_qcom_geni`:

- first failure: NULL/invalid clock path around `clk_get_rate()`
- later failure: NULL parent/wrapper path around
  `geni_se_get_qup_hw_version()`

Local mitigation in `drivers/i2c/busses/i2c-qcom-geni.c`:

- tolerate a missing or error `se.clk` under ACPI
- use a 19.2 MHz fallback clock rate when needed
- avoid calling `clk_get_rate()` on NULL/error clocks
- bail out of ACPI probe when the GENI wrapper parent is missing

This is not considered a final upstream fix. It is a bring-up mitigation that
lets the rest of the boot path be tested.

## Fedora Test Results

Fedora live media reached several failure modes:

- graphical spinner or black screen with no login
- dracut emergency shell
- `/dev/mapper/live-rw` timeout
- `/dev/disk/by-label/Fedora-US-Live-44` not found
- `i2c_qcom_geni` kernel panic when I2C was enabled
- USB/live-root dependency failures when I2C was blacklisted

Determination:

- Fedora stock live media is not the right first debug target.
- The stock Fedora kernel/initramfs does not carry the right Surface Pro X
  assumptions for first boot.
- QEMU Fedora tests were not representative because QEMU uses virtual hardware
  and hides the Qualcomm USB/storage problem.

Fedora remaster tooling is kept in the repo for future work, but it is no
longer the primary path.

## Arch Test Results

Arch image created by:

```sh
sudo scripts/build-arch-spx-image.sh --out build/artifacts/images/arch-spx.img
sudo dd if=build/artifacts/images/arch-spx.img of=/dev/sdc bs=4M status=progress conv=fsync
```

USB partitioning after write:

```text
/dev/sdc1  FAT ESP
/dev/sdc2  ext4 root
```

Observed progress:

- GRUB boots.
- Kernel starts with the Surface Pro X DTB.
- `Machine model: Microsoft Surface Pro X (SQ2)` is printed in DTB mode.
- `/init` from the Arch initramfs runs.
- xHCI host controller initializes.
- USB hubs are detected.
- `uas` and `usb-storage` drivers register.
- `i2c_qcom_geni` no longer panics on the current DTB path.

Current failure:

```text
Waiting for root device PARTUUID=...
```

or equivalent root UUID wait.

Interpretation:

- The root handoff is now the active blocker.
- The kernel can initialize enough USB host infrastructure to see hubs.
- The missing piece is USB mass-storage block-device appearance as `/dev/sd*`
  or a correct userspace wait path that lets it settle.

## Initramfs Debug Changes

The original Arch initramfs used the stock `udev` hook:

```text
HOOKS=(base udev modconf block filesystems fsck)
```

The stock hook runs unbounded:

```sh
udevadm settle
```

On Surface Pro X this can hang before `break=premount` is reached, so the debug
entry did not reliably drop to a shell.

Current custom hooks:

- `spxdebug`: prints cmdline, loaded modules, device candidates, and recent
  USB/storage kernel lines
- `spxudev`: starts udev, triggers subsystem/device events, then runs
  `udevadm settle --timeout=10` instead of waiting forever

Current initramfs config:

```text
MODULES=(usb_storage uas xhci_hcd xhci_plat_hcd xhci_pci dwc3 dwc3_qcom scsi_mod sd_mod ext4)
BINARIES=()
FILES=()
HOOKS=(base spxdebug spxudev modconf block filesystems fsck)
COMPRESSION="gzip"
```

Current default GRUB entry:

```text
Arch SPX - DTB post-udev diagnostic shell
```

This entry adds:

```text
spxdiag=1 spxbreak=postudev
```

Expected result:

- print `/dev/sd*`
- print `/dev/disk/by-uuid`
- print `/dev/disk/by-partuuid`
- print recent USB/xHCI/DWC3/UAS/storage/SCSI/disk messages
- drop to an initramfs shell

## Current GRUB Test Order

1. `Arch SPX - DTB post-udev diagnostic shell`
2. `Arch SPX - DTB bounded-udev root UUID`
3. `Arch SPX - DTB bounded-udev root PARTUUID`
4. `Arch SPX - DTB pre-udev diagnostic shell`
5. `Arch SPX - DTB direct root UUID no initrd`
6. `Arch SPX - ACPI bounded-udev I2C blacklisted`

## What To Capture Next

At the diagnostic shell:

```sh
ls -l /dev/sd* /dev/disk/by-uuid /dev/disk/by-partuuid
dmesg | grep -Ei 'usb|xhci|dwc3|uas|storage|scsi|sd[a-z]|root|partuuid' | tail -120
```

Decision tree:

- If `/dev/sda` appears, fix root resolution or initramfs timing.
- If hubs appear but no storage device appears, focus on USB role/Type-C/DWC3
  controller behavior and required built-in drivers.
- If `spxudev` continues to hang, remove more userspace from the initramfs path
  and test direct kernel root with extra USB timing parameters.
- If DTB display goes black before diagnostics, compare ACPI fallback only for
  display/root behavior, not as the preferred final path.

## Known Useful Boot Parameters

Required or currently useful:

```text
efi=novamap
clk_ignore_unused
rootwait
rootdelay=15
earlycon=efifb
console=tty0
loglevel=8
ignore_loglevel
keep_bootcon
no_console_suspend
panic=-1
nomodeset
usbcore.autosuspend=-1
```

Potential next USB timing experiments:

```text
usbcore.old_scheme_first=1
usbcore.initial_descriptor_timeout=10000
```

## Open Technical Questions

- Does Linux see the USB flash drive as a mass-storage device after xHCI and
  hubs initialize?
- Is Type-C/PD role switching needed before the boot USB storage device appears?
- Are `dwc3_qcom`, PHY, extcon, or Type-C policy pieces missing or loading too
  late?
- Does the Surface firmware expose enough ACPI data for a stable Linux ACPI
  path, or should DTB remain mandatory?
- Which GENI/I2C fix is appropriate upstream: ACPI guard, DMI-specific quirk,
  or rejecting unsupported ACPI-created GENI devices?

## Current Next Action

Boot the current USB default entry and inspect the `spxudev` diagnostic output.
The next code/config change should be based on whether `/dev/sd*` exists in the
initramfs after bounded udev.
