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
context_dir="${SPX_BUILD_DIR}/grub-build-context"
ensure_dir "$out_dir" "$SPX_LOG_DIR/grub"

rm -rf "$context_dir"
ensure_dir "$context_dir"
cp "${grub_repo}/Dockerfile" "${context_dir}/Dockerfile"
cp "${grub_repo}/modules.txt" "${context_dir}/modules.txt"

# The linux-surface GRUB branch currently fails with newer Fedora/GCC because
# bootp.c still uses a 32-bit Unix timestamp where datetime.h now expects 64-bit.
awk '
  { print }
  /&& git checkout "\$\{ref\}"/ {
    print "RUN cd grub && sed -i '\''s/grub_int32_t t = 0;/grub_int64_t t = 0;/g'\'' grub-core/net/bootp.c"
    print "RUN cd grub && sed -i '\''s/struct grub_net_bootp_packet \\*dhcp_ack = \\&pxe_mode->dhcp_ack;/struct grub_net_bootp_packet *dhcp_ack = (struct grub_net_bootp_packet *) \\&pxe_mode->dhcp_ack;/'\'' grub-core/net/drivers/efi/efinet.c && sed -i '\''s/struct grub_net_bootp_packet \\*proxy_offer = \\&pxe_mode->proxy_offer;/struct grub_net_bootp_packet *proxy_offer = (struct grub_net_bootp_packet *) \\&pxe_mode->proxy_offer;/'\'' grub-core/net/drivers/efi/efinet.c"
  }
' "${context_dir}/Dockerfile" > "${context_dir}/Dockerfile.new"
mv "${context_dir}/Dockerfile.new" "${context_dir}/Dockerfile"

info "Building GRUB container with ${engine}"
run_logged "${SPX_LOG_DIR}/grub/container-build.log" \
  "$engine" build -t "$image_name" "$context_dir"

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
