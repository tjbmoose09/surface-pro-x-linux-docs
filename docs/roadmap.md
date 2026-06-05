# Roadmap

## Milestone 0: Documentation Repo

Deliverables:

- project README
- upstream map
- build pipeline
- firmware process
- QEMU test plan
- Fedora plan
- Ubuntu plan
- hardware validation plan
- test matrix

Status:

- in progress

## Milestone 1: Reproducible Kernel Build

Deliverables:

- source lock file
- containerized ARM64 kernel build
- kernel config fragments
- modules and DTBs
- package-ready output directory

Success criteria:

- kernel builds from a clean checkout
- modules install into a staging root
- DTBs are produced and named predictably
- build manifest records all source commits

Current status:

- local `spx/v6.18` kernel builds
- artifacts are staged under `build/artifacts/kernel`
- current built release is `6.18.3+`
- local I2C/GENI bring-up mitigation is being tested

## Milestone 2: Arch USB Root Bring-Up

Deliverables:

- Arch Linux ARM GPT image
- AArch64 GRUB from `grub-image-aarch64`
- local kernel, modules, DTB, firmware, and matching initramfs
- diagnostic GRUB menu
- initramfs hooks for bounded udev and USB/storage diagnostics

Success criteria:

- Surface Pro X boots from USB to GRUB
- DTB kernel path starts reliably
- initramfs starts reliably
- USB mass-storage root appears as a block device
- ext4 root filesystem mounts
- login shell is reached on USB root

Current status:

- GRUB, kernel, initramfs, xHCI, hubs, UAS, and usb-storage are observed
- active blocker is USB root block-device discovery
- `spxdebug` and `spxudev` hooks are active for the next hardware test

## Milestone 3: Firmware and Service Packaging

Deliverables:

- firmware extraction documentation
- local firmware package build
- QCOM service package
- dummy RMTFS package or service override

Success criteria:

- no proprietary firmware is committed
- extracted firmware tree passes file validation
- services install and enable in image builds

## Milestone 4: Fedora KDE Image

Deliverables:

- Fedora RPM packages
- Fedora KDE ARM64 image customization
- QEMU smoke test
- USB hardware boot test

Success criteria:

- image boots in QEMU
- image reaches systemd on Surface Pro X over USB
- logs can be collected

Current status:

- deferred until Arch USB root boot is solved
- previous Fedora live tests failed in dracut/live-root and ACPI I2C paths

## Milestone 5: Ubuntu KDE Image

Deliverables:

- Ubuntu DEB packages
- Ubuntu ARM64 KDE image customization
- QEMU smoke test
- USB hardware boot test

Success criteria:

- image boots in QEMU
- image reaches systemd on Surface Pro X over USB
- logs can be collected

## Milestone 6: Core Hardware Bring-Up

Deliverables:

- Type Cover validation
- battery and charger validation
- thermal validation
- NVMe validation
- WiFi/Bluetooth validation

Success criteria:

- tablet is usable from USB with network and input
- NVMe install path is documented

## Milestone 7: Desktop Usability

Deliverables:

- GPU validation
- Plasma session validation
- brightness validation
- touch and pen validation

Success criteria:

- Plasma is usable on the tablet
- known display handoff issues are documented or mitigated

## Milestone 8: Advanced Hardware

Deliverables:

- suspend/resume work
- audio work
- camera work
- LTE work
- external display work

Success criteria:

- each advanced subsystem has a tracked issue, logs, and a clear owner or next
  technical action
