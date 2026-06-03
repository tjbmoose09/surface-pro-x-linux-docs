#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

kernel="${SPX_KERNEL_ARTIFACT_DIR}/Image"
initramfs=""
dtb=""
grub_efi="${SPX_ARTIFACT_DIR}/grub/bootaa64.efi"
out_dir="$SPX_BOOT_TREE_DIR"
root_arg="root=LABEL=spx-root rw"
extra_args="efi=novamap clk_ignore_unused"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kernel)
      kernel="${2:-}"
      shift 2
      ;;
    --initramfs)
      initramfs="${2:-}"
      shift 2
      ;;
    --dtb)
      dtb="${2:-}"
      shift 2
      ;;
    --grub-efi)
      grub_efi="${2:-}"
      shift 2
      ;;
    --out)
      out_dir="${2:-}"
      shift 2
      ;;
    --root-arg)
      root_arg="${2:-}"
      shift 2
      ;;
    --extra-args)
      extra_args="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Usage: scripts/create-boot-tree.sh --dtb PATH [options]

Creates an EFI/boot tree with BOOTAA64.EFI, kernel, optional initramfs, DTB, and
a GRUB config for Surface Pro X device-tree boot.
EOF
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -f "$kernel" ]] || die "kernel Image missing: ${kernel}"
[[ -f "$grub_efi" ]] || die "GRUB EFI missing: ${grub_efi}"
[[ -n "$dtb" && -f "$dtb" ]] || die "provide --dtb PATH to a Surface Pro X DTB"
if [[ -n "$initramfs" && ! -f "$initramfs" ]]; then
  die "initramfs missing: ${initramfs}"
fi

rm -rf "$out_dir"
ensure_dir "${out_dir}/EFI/BOOT" "${out_dir}/boot/grub" "${out_dir}/boot/spx"

cp "$grub_efi" "${out_dir}/EFI/BOOT/BOOTAA64.EFI"
cp "$kernel" "${out_dir}/boot/spx/Image"
cp "$dtb" "${out_dir}/boot/spx/surface-pro-x.dtb"
if [[ -n "$initramfs" ]]; then
  cp "$initramfs" "${out_dir}/boot/spx/initramfs.img"
fi

{
  printf 'set timeout=5\n'
  printf 'set default=0\n\n'
  printf "menuentry 'Surface Pro X Linux' {\n"
  printf '    devicetree /boot/spx/surface-pro-x.dtb\n'
  printf '    linux /boot/spx/Image %s %s\n' "$root_arg" "$extra_args"
  if [[ -n "$initramfs" ]]; then
    printf '    initrd /boot/spx/initramfs.img\n'
  fi
  printf '}\n'
} > "${out_dir}/boot/grub/grub.cfg"

info "Boot tree created at ${out_dir}"
