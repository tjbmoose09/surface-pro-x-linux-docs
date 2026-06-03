#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

iso="${SPX_QEMU_ISO:-}"
timeout_secs="$SPX_QEMU_TIMEOUT"
firmware_code="${SPX_QEMU_EFI_CODE:-}"
firmware_vars_template="${SPX_QEMU_EFI_VARS:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --iso)
      iso="${2:-}"
      shift 2
      ;;
    --timeout)
      timeout_secs="${2:-}"
      shift 2
      ;;
    --firmware-code)
      firmware_code="${2:-}"
      shift 2
      ;;
    --firmware-vars)
      firmware_vars_template="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Usage: scripts/qemu-iso-smoke.sh --iso PATH [--timeout SECONDS]

Runs a generic ARM64 QEMU boot smoke test from an installer/live ISO. This is
not Surface Pro X hardware emulation.
EOF
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -n "$iso" ]] || die "provide --iso or SPX_QEMU_ISO"
[[ -f "$iso" ]] || die "ISO does not exist: ${iso}"
need_cmd qemu-system-aarch64
need_cmd timeout

if [[ -z "$firmware_code" ]]; then
  for candidate in \
    /usr/share/edk2/aarch64/QEMU_EFI-silent-pflash.raw \
    /usr/share/edk2/aarch64/QEMU_EFI-pflash.raw
  do
    if [[ -f "$candidate" ]]; then
      firmware_code="$candidate"
      break
    fi
  done
fi

if [[ -z "$firmware_vars_template" ]]; then
  for candidate in \
    /usr/share/edk2/aarch64/QEMU_EFI-qemuvars-pflash.raw \
    /usr/share/edk2/aarch64/QEMU_EFI.qemuvars.fd
  do
    if [[ -f "$candidate" ]]; then
      firmware_vars_template="$candidate"
      break
    fi
  done
fi

[[ -n "$firmware_code" && -f "$firmware_code" ]] || die "provide --firmware-code PATH to AArch64 UEFI pflash"
[[ -n "$firmware_vars_template" && -f "$firmware_vars_template" ]] || die "provide --firmware-vars PATH to writable vars template"

ensure_dir "${SPX_BUILD_DIR}/qemu" "${SPX_LOG_DIR}/qemu"
vars_file="${SPX_BUILD_DIR}/qemu/$(basename "$iso").vars.raw"
log_file="${SPX_LOG_DIR}/qemu/$(basename "$iso").iso.log"
cp "$firmware_vars_template" "$vars_file"
chmod 0600 "$vars_file"

info "Running generic ARM64 ISO QEMU smoke test for ${iso}"
info "Logging to ${log_file}"
set +e
timeout "$timeout_secs" \
  qemu-system-aarch64 \
    -machine virt,gic-version=3 \
    -cpu cortex-a76 \
    -m "$SPX_QEMU_MEMORY" \
    -smp "$SPX_QEMU_CPUS" \
    -drive "if=pflash,format=raw,readonly=on,file=${firmware_code}" \
    -drive "if=pflash,format=raw,file=${vars_file}" \
    -device virtio-scsi-pci,id=scsi0 \
    -drive "if=none,media=cdrom,readonly=on,file=${iso},id=cdrom0" \
    -device scsi-cd,drive=cdrom0,bus=scsi0.0 \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0 \
    -nographic \
    -serial mon:stdio \
  2>&1 | tee "$log_file"
qemu_status=${PIPESTATUS[0]}
set -e

if grep -Eiq 'GRUB version|Booting `.*Fedora|The media check is complete, the result is: PASS|Started .*Display Manager|login:' "$log_file"; then
  info "QEMU ISO smoke test observed a boot marker"
  exit 0
fi

if [[ "$qemu_status" -eq 124 ]]; then
  die "QEMU timed out without an observed ISO boot marker; see ${log_file}"
fi

die "QEMU exited without an observed ISO boot marker; see ${log_file}"
