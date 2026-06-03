#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

out_dir="${SPX_ARTIFACT_DIR}/grub"
skip_fetch=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      out_dir="${2:-}"
      shift 2
      ;;
    --skip-fetch)
      skip_fetch=true
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Usage: scripts/build-grub.sh [--out PATH] [--skip-fetch]

Builds bootaa64.efi from linux-surface/grub-image-aarch64 using podman or
docker.
EOF
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

if [[ "$skip_fetch" == false ]]; then
  "${SCRIPT_DIR}/fetch-upstreams.sh" --only grub-image-aarch64
fi

grub_repo="$(repo_path_for grub-image-aarch64)"
modules_file="${grub_repo}/modules.txt"
[[ -f "$modules_file" ]] || die "missing GRUB modules file: ${modules_file}"

engine="$(detect_container_engine)" || die "podman or docker is required to build GRUB"
image_name="spx-grub-aarch64"
ensure_dir "$out_dir" "$SPX_LOG_DIR/grub"

info "Building GRUB container with ${engine}"
run_logged "${SPX_LOG_DIR}/grub/container-build.log" \
  "$engine" build -t "$image_name" "$grub_repo"

mapfile -t modules < <(tr '[:space:]' '\n' < "$modules_file" | sed '/^$/d')

volume_arg="${out_dir}:/output"
if [[ "$engine" == "podman" ]]; then
  volume_arg="${volume_arg}:Z"
fi

info "Generating ${out_dir}/bootaa64.efi"
run_logged "${SPX_LOG_DIR}/grub/mkimage.log" \
  "$engine" run --rm \
    -v "$volume_arg" \
    "$image_name" \
    aarch64-grub-mkimage \
      -O arm64-efi \
      -o /output/bootaa64.efi \
      --prefix= \
      "${modules[@]}"

[[ -f "${out_dir}/bootaa64.efi" ]] || die "GRUB output missing"
info "GRUB image is ${out_dir}/bootaa64.efi"
