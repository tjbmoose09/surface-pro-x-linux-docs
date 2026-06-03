#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

containerfile="${SPX_REPO_ROOT}/containers/Containerfile.fedora-toolchain"
image_name="spx-fedora-toolchain"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --containerfile)
      containerfile="${2:-}"
      shift 2
      ;;
    --image-name)
      image_name="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Usage: scripts/container-shell.sh [--containerfile PATH] [--image-name NAME]

Builds and opens a shell in the starter toolchain container.
EOF
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -f "$containerfile" ]] || die "containerfile missing: ${containerfile}"
engine="$(detect_container_engine)" || die "podman or docker is required"

"$engine" build -t "$image_name" -f "$containerfile" "$SPX_REPO_ROOT"

volume_arg="${SPX_REPO_ROOT}:/work"
if [[ "$engine" == "podman" ]]; then
  volume_arg="${volume_arg}:Z"
fi

"$engine" run --rm -it \
  -v "$volume_arg" \
  -w /work \
  "$image_name" \
  bash
