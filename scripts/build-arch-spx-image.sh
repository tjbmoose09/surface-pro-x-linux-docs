#!/usr/bin/env bash
# Build an Arch Linux ARM Surface Pro X test image.
#
# This wraps linux-surface/aarch64-arch-mkimg, then replaces its boot payload
# with the locally built SPX kernel, DTB, modules, firmware, and a focused GRUB
# test menu.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

profile="persistent"
out="${SPX_ARTIFACT_DIR}/images/arch-spx.img"
skip_build=0
skip_fetch=0
write_device=""

usage() {
  cat <<'EOF'
Usage:
  scripts/build-arch-spx-image.sh [options]

Options:
  --out PATH        Output raw disk image path.
  --profile NAME    aarch64-arch-mkimg profile, default: persistent.
  --skip-build      Reuse build/src/aarch64-arch-mkimg/build/disk.img.
  --skip-fetch      Do not update upstream source repos.
  --write DEVICE    After building, dd the image to DEVICE, e.g. /dev/sdc.
  -h, --help        Show this help.

The image is Arch Linux ARM with:
  - linux-surface/grub-image-aarch64 BOOTAA64.EFI
  - local patched SPX kernel Image
  - sc8180x-surface-pro-x.dtb loaded by GRUB
  - local modules installed under /usr/lib/modules
  - linux-surface/aarch64-firmware copied into /usr/lib/firmware

Primary GRUB entries are DTB-first and use root=PARTUUID so the first test can
boot without relying on a matching initramfs.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      out="${2:-}"
      shift 2
      ;;
    --profile)
      profile="${2:-}"
      shift 2
      ;;
    --skip-build)
      skip_build=1
      shift
      ;;
    --skip-fetch)
      skip_fetch=1
      shift
      ;;
    --write)
      write_device="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -n "$out" ]] || die "--out PATH cannot be empty"

need_cmd podman
need_cmd rsync
need_cmd losetup
need_cmd mount
need_cmd umount
need_cmd findmnt
need_cmd blkid
need_cmd sgdisk
need_cmd dd

if [[ $EUID -ne 0 ]]; then
  if ! have_cmd sudo; then
    die "run as root or install sudo"
  fi
  exec sudo "$0" \
    --out "$out" \
    --profile "$profile" \
    $([[ "$skip_build" == 1 ]] && printf '%s' --skip-build) \
    $([[ "$skip_fetch" == 1 ]] && printf '%s' --skip-fetch) \
    $([[ -n "$write_device" ]] && printf '%s %q' --write "$write_device")
fi

if [[ "$skip_fetch" != 1 ]]; then
  "${SCRIPT_DIR}/fetch-upstreams.sh" --only aarch64-arch-mkimg
  "${SCRIPT_DIR}/fetch-upstreams.sh" --only aarch64-firmware
fi

mkimg_repo="$(repo_path_for aarch64-arch-mkimg)"
firmware_repo="$(repo_path_for aarch64-firmware)"
kernel_dir="${SPX_KERNEL_ARTIFACT_DIR}"
grub_efi="${SPX_ARTIFACT_DIR}/grub/bootaa64.efi"
kernel_image="${kernel_dir}/Image"
kernel_release_file="${kernel_dir}/kernel.release"
dtb="${kernel_dir}/dtbs/qcom/sc8180x-surface-pro-x.dtb"

[[ -d "$mkimg_repo" ]] || die "missing aarch64-arch-mkimg repo; run scripts/fetch-upstreams.sh"
[[ -d "$firmware_repo/firmware" ]] || die "missing aarch64 firmware repo; run scripts/fetch-upstreams.sh"
[[ -f "$grub_efi" ]] || die "missing ${grub_efi}; run make grub"
[[ -f "$kernel_image" ]] || die "missing ${kernel_image}; run scripts/build-kernel.sh"
[[ -f "$kernel_release_file" ]] || die "missing ${kernel_release_file}; run scripts/install-kernel-artifacts.sh"
[[ -f "$dtb" ]] || die "missing ${dtb}; run scripts/build-kernel.sh"

kver="$(<"$kernel_release_file")"
modules_src="${kernel_dir}/modules/lib/modules/${kver}"
[[ -d "$modules_src" ]] || die "missing modules for ${kver}; run scripts/install-kernel-artifacts.sh"

img_src="${mkimg_repo}/build/disk.img"
in_place=0
if [[ "$skip_build" != 1 ]]; then
  info "Building upstream Arch ARM image profile '${profile}'"
  container_context="${SPX_BUILD_DIR}/arch-mkimg-container"
  rm -rf "$container_context"
  mkdir -p "$container_context"
  rsync -a --exclude build "$mkimg_repo/" "$container_context/"
  sed -i 's|^FROM archlinux/archlinux$|FROM docker.io/archlinux/archlinux|' \
    "$container_context/Dockerfile"
  sed -i '/_rootfs_copy_profile/a\    grep -q "^DisableSandbox" "${_DIR_BUILD_ROOTFS}/etc/pacman.conf" || sed -i "/^\\[options\\]/a DisableSandbox" "${_DIR_BUILD_ROOTFS}/etc/pacman.conf"' \
    "$container_context/lib/base/rootfs.sh"
  sed -i 's|root_part_size=$(( (root_size\*110)/100/(1024\*1024) + 1))|root_part_size=$(( (root_size*130)/100/(1024*1024) + 1024))|' \
    "$container_context/lib/base/img.sh"
  cat > "$container_context/profiles/default/packages/install" <<'EOF'
base
iwd
usbutils
dosfstools
util-linux
wget
EOF
  # The upstream qcom-wifi module currently fails because rmtfs-dummy carries a
  # patch that no longer applies to linux-msm/rmtfs. It is not needed for the
  # first boot/root-mount experiment, so keep it out of the temporary profile.
  rm -f "$container_context/profiles/default/modules/04-qcom-wifi.sh"
  podman build -t spx-aarch64-arch-mkimg "$container_context"
  mkdir -p "${mkimg_repo}/build"
  podman run --rm --privileged \
    --mount type=tmpfs,destination=/run/shm \
    -v /dev:/dev \
    -v "${mkimg_repo}/build":/build \
    spx-aarch64-arch-mkimg "$profile"
fi

if [[ "$skip_build" == 1 && ! -f "$img_src" && -f "$out" ]]; then
  img_src="$out"
  in_place=1
fi

[[ -f "$img_src" ]] || die "upstream image not found at ${img_src}"
ensure_dir "$(dirname "$out")" "${SPX_LOG_DIR}/arch"
if [[ "$in_place" != 1 ]]; then
  cp "$img_src" "$out"
fi

loopdev=""
efi_mnt=""
root_mnt=""
bind_mounts=()
cleanup() {
  set +e
  for ((i=${#bind_mounts[@]}-1; i>=0; i--)); do
    if findmnt -rn "${bind_mounts[$i]}" >/dev/null 2>&1; then
      umount -R "${bind_mounts[$i]}"
    fi
  done
  if [[ -n "$efi_mnt" && -d "$efi_mnt" ]] && findmnt -rn "$efi_mnt" >/dev/null 2>&1; then
    umount "$efi_mnt"
  fi
  if [[ -n "$root_mnt" && -d "$root_mnt" ]] && findmnt -rn "$root_mnt" >/dev/null 2>&1; then
    umount "$root_mnt"
  fi
  [[ -n "$loopdev" ]] && losetup -d "$loopdev" >/dev/null 2>&1
  [[ -n "$efi_mnt" ]] && rm -rf "$efi_mnt"
  [[ -n "$root_mnt" ]] && rm -rf "$root_mnt"
}
trap cleanup EXIT

info "Mounting ${out}"
loopdev="$(losetup --show -f -P "$out")"
partprobe "$loopdev" >/dev/null 2>&1 || true
efi_mnt="$(mktemp -d -t spx-arch-efi.XXXXXXXXXX)"
root_mnt="$(mktemp -d -t spx-arch-root.XXXXXXXXXX)"
mount "${loopdev}p1" "$efi_mnt"
mount "${loopdev}p2" "$root_mnt"

root_partuuid="$(blkid -s PARTUUID -o value "${loopdev}p2")"
root_uuid="$(blkid -s UUID -o value "${loopdev}p2")"
[[ -n "$root_partuuid" ]] || die "could not read root PARTUUID"
[[ -n "$root_uuid" ]] || die "could not read root UUID"

info "Installing local SPX boot payload"
install -d "$efi_mnt/EFI/BOOT"
install -m 0644 "$grub_efi" "$efi_mnt/EFI/BOOT/BOOTAA64.EFI"
install -m 0644 "$grub_efi" "$efi_mnt/EFI/BOOT/bootaa64.efi"

install -d "$root_mnt/boot/dtb/linux-surface/qcom"
install -m 0644 "$kernel_image" "$root_mnt/boot/vmlinuz-linux-surface-spx"
install -m 0644 "$kernel_image" "$root_mnt/boot/Image"
install -m 0644 "$dtb" "$root_mnt/boot/dtb/linux-surface/qcom/sc8180x-surface-pro-x.dtb"
install -m 0644 "$dtb" "$root_mnt/boot/surface-pro-x.dtb"
touch "$root_mnt/boot/.aarch64-arch-boot"

install -d "$root_mnt/usr/lib/modules"
rm -rf "$root_mnt/usr/lib/modules/${kver}"
rsync -aHAX --delete "$modules_src/" "$root_mnt/usr/lib/modules/${kver}/"
depmod -b "$root_mnt" "$kver"

install -d "$root_mnt/usr/lib/firmware"
rsync -aHAX --delete --force "$firmware_repo/firmware/" "$root_mnt/usr/lib/firmware/"

install -d "$root_mnt/usr/lib/initcpio/install" "$root_mnt/usr/lib/initcpio/hooks"
cat > "$root_mnt/usr/lib/initcpio/install/spxdebug" <<'EOF'
#!/usr/bin/ash

build() {
    add_runscript
}

help() {
    cat <<HELPEOF
Surface Pro X early initramfs debug hook.
HELPEOF
}
EOF
cat > "$root_mnt/usr/lib/initcpio/hooks/spxdebug" <<'EOF'
#!/usr/bin/ash

_spx_diag() {
    echo ":: SPX initramfs diagnostics"
    echo ":: cmdline"
    cat /proc/cmdline || true
    echo ":: loaded modules"
    lsmod || true
    echo ":: /dev root candidates"
    ls -l /dev/sd* /dev/xvd* /dev/vd* /dev/disk/by-uuid /dev/disk/by-partuuid 2>/dev/null || true
    echo ":: recent USB/storage lines"
    dmesg | grep -Ei "usb|xhci|dwc3|uas|storage|scsi|sd[a-z]|blk|partuuid|root" | tail -120 || true
}

run_hook() {
    if grep -qw "spxdiag=1" /proc/cmdline; then
        _spx_diag
    fi
    if grep -qw "spxbreak=preudev" /proc/cmdline; then
        _spx_diag
        echo ":: SPX pre-udev shell requested. Type exit to continue."
        launch_interactive_shell
    fi
}

run_latehook() {
    if grep -qw "spxdiag=1" /proc/cmdline; then
        _spx_diag
    fi
    if grep -qw "spxbreak=late" /proc/cmdline; then
        _spx_diag
        echo ":: SPX late shell requested. Type exit to continue."
        launch_interactive_shell
    fi
}
EOF
cat > "$root_mnt/usr/lib/initcpio/install/spxudev" <<'EOF'
#!/bin/bash

build() {
    map add_binary \
        "/usr/lib/systemd/systemd-udevd" \
        "/usr/bin/udevadm" \
        "/usr/lib/udev/ata_id" \
        "/usr/lib/udev/scsi_id" \
        "/usr/lib/libkmod.so.2"

    if [[ -x "/usr/bin/systemd-tmpfiles" ]]; then
        add_binary "/usr/bin/systemd-tmpfiles"
    fi

    map add_udev_rule \
        "50-udev-default.rules" \
        "60-persistent-storage.rules" \
        "64-btrfs.rules" \
        "80-drivers.rules"

    for f in /usr/lib/udev/hwdb.bin /etc/udev/hwdb.bin; do
        [[ -f "$f" ]] && add_file "$f"
    done

    add_runscript
}

help() {
    cat <<HELPEOF
Surface Pro X bounded udev hook. Starts udev and triggers devices, but does not
allow udevadm settle to block the initramfs indefinitely.
HELPEOF
}
EOF
cat > "$root_mnt/usr/lib/initcpio/hooks/spxudev" <<'EOF'
#!/usr/bin/ash

_spx_udev_diag() {
    echo ":: SPX udev diagnostics"
    ls -l /dev/sd* /dev/xvd* /dev/vd* /dev/disk/by-uuid /dev/disk/by-partuuid 2>/dev/null || true
    dmesg | grep -Ei "usb|xhci|dwc3|uas|storage|scsi|sd[a-z]|blk|partuuid|root" | tail -160 || true
}

run_earlyhook() {
    local quiet
    if command -v /usr/bin/systemd-tmpfiles >/dev/null 2>&1; then
        kmod static-nodes --format=tmpfiles --output=/run/tmpfiles.d/kmod.conf
        /usr/bin/systemd-tmpfiles --prefix=/dev --create --boot
    fi
    quiet="$(getarg quiet)"
    if [ "${quiet}" = "y" ]; then
        /usr/lib/systemd/systemd-udevd --daemon --resolve-names=never >/dev/null 2>&1
    else
        /usr/lib/systemd/systemd-udevd --daemon --resolve-names=never
    fi
    udevd_running=1
}

run_hook() {
    echo ":: SPX triggering uevents with bounded settle"
    udevadm trigger --action=add --type=subsystems || true
    udevadm trigger --action=add --type=devices || true
    udevadm settle --timeout=10 || true
    _spx_udev_diag
    if grep -qw "spxbreak=postudev" /proc/cmdline; then
        echo ":: SPX post-udev shell requested. Type exit to continue."
        launch_interactive_shell
    fi
}

run_cleanuphook() {
    udevadm control --exit || true
    udevadm info --cleanup-db || true
}
EOF
chmod 0644 \
  "$root_mnt/usr/lib/initcpio/install/spxdebug" \
  "$root_mnt/usr/lib/initcpio/hooks/spxdebug" \
  "$root_mnt/usr/lib/initcpio/install/spxudev" \
  "$root_mnt/usr/lib/initcpio/hooks/spxudev"

cat > "$root_mnt/etc/mkinitcpio-spx.conf" <<'EOF'
MODULES=(usb_storage uas xhci_hcd xhci_plat_hcd xhci_pci dwc3 dwc3_qcom scsi_mod sd_mod ext4)
BINARIES=()
FILES=()
HOOKS=(base spxdebug spxudev modconf block filesystems fsck)
COMPRESSION="gzip"
EOF

if have_cmd qemu-aarch64-static; then
  install -d "$root_mnt/proc" "$root_mnt/sys" "$root_mnt/dev" "$root_mnt/run" "$root_mnt/usr/bin"
  install -m 0755 "$(command -v qemu-aarch64-static)" "$root_mnt/usr/bin/qemu-aarch64-static"
  mount -t proc proc "$root_mnt/proc"
  bind_mounts+=("$root_mnt/proc")
  mount --rbind /sys "$root_mnt/sys"
  mount --make-rslave "$root_mnt/sys"
  bind_mounts+=("$root_mnt/sys")
  mount --rbind /dev "$root_mnt/dev"
  mount --make-rslave "$root_mnt/dev"
  bind_mounts+=("$root_mnt/dev")
  mount --rbind /run "$root_mnt/run"
  mount --make-rslave "$root_mnt/run"
  bind_mounts+=("$root_mnt/run")
  info "Generating matching initramfs-spx.img for ${kver}"
  chroot "$root_mnt" /usr/bin/mkinitcpio \
    -c /etc/mkinitcpio-spx.conf \
    -k "$kver" \
    -g /boot/initramfs-spx.img
else
  warn "qemu-aarch64-static not found; skipping /boot/initramfs-spx.img generation"
fi

install -d "$root_mnt/etc/modprobe.d" \
  "$root_mnt/etc/systemd/system" \
  "$root_mnt/etc/systemd/system/multi-user.target.wants"
cat > "$root_mnt/etc/modprobe.d/spx-early-debug.conf" <<'EOF'
# Keep the unstable Type-C policy modules out of the first boot pass.
blacklist pmic_glink_altmode
blacklist ucsi_glink
blacklist qcom_pmic_tcpm
EOF

cat > "$root_mnt/etc/systemd/system/spx-boot-log.service" <<'EOF'
[Unit]
Description=Capture Surface Pro X first-boot diagnostics
DefaultDependencies=no
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'mkdir -p /var/log/spx; date -Is > /var/log/spx/boot.txt; cat /proc/cmdline >> /var/log/spx/boot.txt; dmesg > /var/log/spx/dmesg.txt; journalctl -b --no-pager > /var/log/spx/journal.txt || true'

[Install]
WantedBy=multi-user.target
EOF
ln -sf /etc/systemd/system/spx-boot-log.service \
  "$root_mnt/etc/systemd/system/multi-user.target.wants/spx-boot-log.service"

install -d "$efi_mnt/EFI/BOOT" "$root_mnt/boot/grub"
cat > "$efi_mnt/EFI/BOOT/grub.cfg" <<EOF
insmod part_gpt
insmod fat
insmod ext2
insmod gzio

set timeout=30
set default=0

set spx_base="rw rootwait rootdelay=15 efi=novamap clk_ignore_unused earlycon=efifb console=tty0 loglevel=8 ignore_loglevel keep_bootcon no_console_suspend panic=-1 nomodeset usbcore.autosuspend=-1"

menuentry "Arch SPX - DTB post-udev diagnostic shell" {
    search --no-floppy --set=root --file /boot/.aarch64-arch-boot
    devicetree /boot/dtb/linux-surface/qcom/sc8180x-surface-pro-x.dtb
    linux /boot/vmlinuz-linux-surface-spx root=UUID=${root_uuid} \${spx_base} spxdiag=1 spxbreak=postudev
    initrd /boot/initramfs-spx.img
}

menuentry "Arch SPX - DTB bounded-udev root UUID" {
    search --no-floppy --set=root --file /boot/.aarch64-arch-boot
    devicetree /boot/dtb/linux-surface/qcom/sc8180x-surface-pro-x.dtb
    linux /boot/vmlinuz-linux-surface-spx root=UUID=${root_uuid} \${spx_base} spxdiag=1
    initrd /boot/initramfs-spx.img
}

menuentry "Arch SPX - DTB bounded-udev root PARTUUID" {
    search --no-floppy --set=root --file /boot/.aarch64-arch-boot
    devicetree /boot/dtb/linux-surface/qcom/sc8180x-surface-pro-x.dtb
    linux /boot/vmlinuz-linux-surface-spx root=PARTUUID=${root_partuuid} \${spx_base} spxdiag=1
    initrd /boot/initramfs-spx.img
}

menuentry "Arch SPX - DTB pre-udev diagnostic shell" {
    search --no-floppy --set=root --file /boot/.aarch64-arch-boot
    devicetree /boot/dtb/linux-surface/qcom/sc8180x-surface-pro-x.dtb
    linux /boot/vmlinuz-linux-surface-spx root=UUID=${root_uuid} \${spx_base} spxdiag=1 spxbreak=preudev
    initrd /boot/initramfs-spx.img
}

menuentry "Arch SPX - DTB direct root UUID no initrd" {
    search --no-floppy --set=root --file /boot/.aarch64-arch-boot
    devicetree /boot/dtb/linux-surface/qcom/sc8180x-surface-pro-x.dtb
    linux /boot/vmlinuz-linux-surface-spx root=UUID=${root_uuid} \${spx_base}
}

menuentry "Arch SPX - ACPI bounded-udev I2C blacklisted" {
    search --no-floppy --set=root --file /boot/.aarch64-arch-boot
    linux /boot/vmlinuz-linux-surface-spx root=UUID=${root_uuid} \${spx_base} spxdiag=1 modprobe.blacklist=i2c_qcom_geni,pmic_glink_altmode,ucsi_glink,qcom_pmic_tcpm
    initrd /boot/initramfs-spx.img
}

menuentry "Shutdown" {
    halt
}
EOF
cp "$efi_mnt/EFI/BOOT/grub.cfg" "$root_mnt/boot/grub/grub.cfg"

sync
info "Arch SPX image ready: ${out}"
info "Root PARTUUID: ${root_partuuid}"
info "Kernel: ${kver}"

if [[ -n "$write_device" ]]; then
  [[ -b "$write_device" ]] || die "write target is not a block device: ${write_device}"
  info "Writing ${out} to ${write_device}"
  umount "$efi_mnt"
  umount "$root_mnt"
  losetup -d "$loopdev"
  loopdev=""
  dd if="$out" of="$write_device" bs=4M status=progress conv=fsync
  sync
  eject "$write_device" 2>/dev/null || true
  info "Wrote and ejected ${write_device}"
fi
