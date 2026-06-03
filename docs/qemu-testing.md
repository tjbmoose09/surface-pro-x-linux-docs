# QEMU Testing

QEMU is useful, but it is not a Surface Pro X emulator.

## What QEMU Can Validate

Use QEMU for:

- ARM64 image boot smoke tests
- EFI partition sanity
- GRUB load path
- kernel and initramfs boot path
- root filesystem layout
- package installation
- systemd unit enablement
- first-boot scripts
- SSH availability
- KDE/SDDM package presence and basic startup
- artifact reproducibility

## What QEMU Cannot Validate

QEMU cannot validate these Surface Pro X features without a custom Surface Pro X
machine model:

- Surface Aggregator Module behavior
- Type Cover keyboard and touchpad path
- battery and charger support
- Surface thermal sensors
- Surface RTC behavior
- Adreno GPU acceleration
- real display handoff issues
- NVMe quirks
- WiFi remote processor firmware
- Bluetooth firmware behavior
- touch and pen
- suspend and resume
- audio subsystem
- LTE modem
- cameras
- external display ports

Those tests must run on a physical Surface Pro X.

## Baseline QEMU Machine

Use the generic ARM64 `virt` board:

```sh
qemu-system-aarch64 \
  -machine virt,gic-version=3 \
  -cpu cortex-a76 \
  -m 4096 \
  -smp 4 \
  -bios QEMU_EFI.fd \
  -drive if=none,file=build/images/fedora-spx.raw,format=raw,id=hd0 \
  -device virtio-blk-pci,drive=hd0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -serial mon:stdio
```

Use distro-provided AArch64 QEMU EFI firmware where available.

## Smoke Test Targets

### Image Boots

Pass criteria:

- QEMU reaches systemd.
- No initramfs panic.
- Root filesystem mounts read-write.
- SSH starts for development images.

### Package Layout

Pass criteria:

- kernel package installed
- modules installed under `/lib/modules`
- DTBs installed under expected boot path
- initramfs exists
- firmware helper package installed
- QCOM service package installed

### Bootloader

Pass criteria:

- EFI partition has `EFI/BOOT/BOOTAA64.EFI`
- GRUB config exists
- GRUB config has a Surface Pro X hardware entry
- required kernel args are present

### Desktop

Pass criteria:

- Plasma packages installed
- display manager unit enabled
- noninteractive desktop package validation passes

QEMU desktop tests are smoke tests only. A successful QEMU Plasma start does not
prove usable Plasma on the tablet.

## Logs

Keep QEMU logs under:

```text
build/logs/qemu/
```

Commit only sanitized excerpts when they document a bug or fix.
