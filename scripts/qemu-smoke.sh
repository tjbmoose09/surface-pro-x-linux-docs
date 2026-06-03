#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

image="${SPX_QEMU_IMAGE:-}"
bios="${SPX_QEMU_BIOS:-}"
format="${SPX_QEMU_FORMAT:-raw}"
timeout_secs="$SPX_QEMU_TIMEOUT"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)
      image="${2:-}"
      shift 2
      ;;
    --bios)
      bios="${2:-}"
      shift 2
      ;;
    --format)
      format="${2:-}"
      shift 2
      ;;
    --timeout)
      timeout_secs="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Usage: scripts/qemu-smoke.sh --image PATH [--bios PATH] [--format raw|qcow2]

Runs a generic ARM64 QEMU boot smoke test. This is not Surface Pro X hardware
emulation.
EOF
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -n "$image" ]] || die "provide --image or SPX_QEMU_IMAGE"
[[ -f "$image" ]] || die "image does not exist: ${image}"
need_cmd qemu-system-aarch64
need_cmd timeout

if [[ -z "$bios" ]]; then
  for candidate in \
    /usr/share/edk2/aarch64/QEMU_EFI.fd \
    /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
    /usr/share/AAVMF/AAVMF_CODE.fd \
    /usr/share/edk2/aarch64/QEMU_EFI-pflash.raw
  do
    if [[ -f "$candidate" ]]; then
      bios="$candidate"
      break
    fi
  done
fi

[[ -n "$bios" && -f "$bios" ]] || die "provide --bios PATH to AArch64 UEFI firmware"

ensure_dir "${SPX_LOG_DIR}/qemu"
log_file="${SPX_LOG_DIR}/qemu/$(basename "$image").log"

info "Running generic ARM64 QEMU smoke test for ${image}"
set +e
timeout "$timeout_secs" \
  qemu-system-aarch64 \
    -machine virt,gic-version=3 \
    -cpu cortex-a76 \
    -m "$SPX_QEMU_MEMORY" \
    -smp "$SPX_QEMU_CPUS" \
    -bios "$bios" \
    -drive "if=none,file=${image},format=${format},id=hd0" \
    -device virtio-blk-pci,drive=hd0 \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0 \
    -nographic \
  2>&1 | tee "$log_file"
qemu_status=${PIPESTATUS[0]}
set -e

if grep -Eiq 'Reached target .*Multi-User|Started .*Display Manager|login:|Welcome to' "$log_file"; then
  info "QEMU smoke test observed a boot marker"
  exit 0
fi

if [[ "$qemu_status" -eq 124 ]]; then
  die "QEMU timed out without an observed boot marker; see ${log_file}"
fi

die "QEMU exited without an observed boot marker; see ${log_file}"
