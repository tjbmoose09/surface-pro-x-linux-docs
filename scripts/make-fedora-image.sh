#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

base_image=""
output_image="${SPX_ARTIFACT_DIR}/images/fedora-spx.qcow2"
toolkit_rpm=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-image)
      base_image="${2:-}"
      shift 2
      ;;
    --out)
      output_image="${2:-}"
      shift 2
      ;;
    --toolkit-rpm)
      toolkit_rpm="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Usage: scripts/make-fedora-image.sh --base-image PATH [--out PATH] [--toolkit-rpm PATH]

Copies a Fedora AArch64 base image to a working qcow2 image and optionally uses
virt-customize to install the starter toolkit RPM.
EOF
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -n "$base_image" && -f "$base_image" ]] || die "provide --base-image PATH"
need_cmd qemu-img
ensure_dir "$(dirname "$output_image")"

qemu-img convert -O qcow2 "$base_image" "$output_image"

if [[ -n "$toolkit_rpm" ]]; then
  [[ -f "$toolkit_rpm" ]] || die "toolkit RPM missing: ${toolkit_rpm}"
  need_cmd virt-customize
  rpm_name="$(basename "$toolkit_rpm")"
  virt-customize -a "$output_image" \
    --upload "${toolkit_rpm}:/tmp/${rpm_name}" \
    --run-command "dnf install -y /tmp/${rpm_name} || rpm -Uvh /tmp/${rpm_name}"
fi

info "Fedora working image created at ${output_image}"
