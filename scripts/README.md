# Scripts

This directory contains the starter build and validation tools.

Implemented scripts:

- `check-host.sh`
- `fetch-upstreams.sh`
- `build-kernel.sh`
- `extract-firmware.sh`
- `validate-firmware.sh`
- `build-grub.sh`
- `create-boot-tree.sh`
- `build-fedora-packages.sh`
- `build-ubuntu-packages.sh`
- `make-fedora-image.sh`
- `make-ubuntu-image.sh`
- `qemu-smoke.sh`
- `collect-hardware-logs.sh`
- `container-shell.sh`

The scripts are intentionally staged. The first working goal is source fetch,
kernel artifact generation, firmware staging, generic QEMU smoke testing, and
physical-device log collection. Full Fedora and Ubuntu kernel/image packaging is
a later milestone.
