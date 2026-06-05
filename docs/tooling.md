# Tooling

The repository now includes starter scripts for the first phase of Surface Pro X
Linux enablement.

## Quick Start

Check the host:

```sh
make check-host
```

Fetch upstream sources:

```sh
make fetch-upstreams
```

Prepare a kernel config without doing a full build:

```sh
scripts/build-kernel.sh --prepare-only
```

Build the kernel:

```sh
make kernel
```

Stage built kernel artifacts:

```sh
make kernel-install-artifacts
```

Extract firmware from a mounted Windows installation or recovery image:

```sh
SPX_WINDOWS_ROOT=/path/to/windows-root make firmware
```

Validate staged firmware:

```sh
make validate-firmware
```

Build GRUB:

```sh
make grub
```

Create a boot tree after kernel, GRUB, and DTB artifacts exist:

```sh
make boot-tree DTB=/path/to/surface-pro-x.dtb INITRAMFS=/path/to/initramfs.img
```

Run a generic ARM64 QEMU smoke test:

```sh
make qemu-smoke IMAGE=/path/to/aarch64-image.raw
```

Build the current Arch Linux ARM Surface Pro X image:

```sh
make arch-spx-image
```

Build and write it to a USB target:

```sh
sudo scripts/build-arch-spx-image.sh --write /dev/sdX
```

Collect logs on the physical tablet:

```sh
make hardware-logs
```

## Source Layout

Fetched upstreams land under:

```text
build/src/
```

Generated source manifests land under:

```text
build/manifests/
```

Build outputs land under:

```text
build/artifacts/
```

## Container

Open the starter Fedora toolchain container with:

```sh
make container-shell
```

The container is useful for source fetching, documentation checks, package
skeletons, and generic build attempts. It does not replace hardware testing on
the Surface Pro X.

## Current Limit

The active tool path is Arch-first. Fedora and Ubuntu image flows still need the
next implementation phase: kernel package specs, initramfs hooks, local package
repositories, and image customization that installs the Surface Pro X kernel and
boot files.
