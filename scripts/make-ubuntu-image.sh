#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

base_image=""
output_image="${SPX_ARTIFACT_DIR}/images/ubuntu-spx.qcow2"
toolkit_deb=""

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
    --toolkit-deb)
      toolkit_deb="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Usage: scripts/make-ubuntu-image.sh --base-image PATH [--out PATH] [--toolkit-deb PATH]

Copies an Ubuntu ARM64 base image to a working qcow2 image and optionally uses
virt-customize to install the starter toolkit DEB.
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

if [[ -n "$toolkit_deb" ]]; then
  [[ -f "$toolkit_deb" ]] || die "toolkit DEB missing: ${toolkit_deb}"
  need_cmd virt-customize
  deb_name="$(basename "$toolkit_deb")"
  virt-customize -a "$output_image" \
    --upload "${toolkit_deb}:/tmp/${deb_name}" \
    --run-command "apt-get update && apt-get install -y /tmp/${deb_name}"
fi

info "Ubuntu working image created at ${output_image}"
