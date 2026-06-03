# Containers

`Containerfile.fedora-toolchain` provides a starter build environment for docs,
source fetching, package skeletons, QEMU smoke tests, and LLVM-based kernel
build attempts.

Start it with:

```sh
scripts/container-shell.sh
```

The container does not grant access to physical Surface Pro X hardware. Hardware
validation still runs on the tablet.
