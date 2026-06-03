#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

windows_root="${SPX_WINDOWS_ROOT:-}"
out_dir="$SPX_FIRMWARE_OUT"
skip_fetch=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --windows-root)
      windows_root="${2:-}"
      shift 2
      ;;
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
Usage: scripts/extract-firmware.sh --windows-root PATH [--out PATH] [--skip-fetch]

Extracts Surface Pro X firmware from a mounted Windows installation or extracted
Surface recovery image using linux-surface/aarch64-firmware.

This script does not commit or redistribute firmware.
EOF
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -n "$windows_root" ]] || die "provide --windows-root or SPX_WINDOWS_ROOT"
[[ -d "$windows_root" ]] || die "Windows root does not exist: ${windows_root}"

if [[ "$skip_fetch" == false ]]; then
  "${SCRIPT_DIR}/fetch-upstreams.sh" --only aarch64-firmware
fi

firmware_repo="$(repo_path_for aarch64-firmware)"
helper="${firmware_repo}/scripts/getfw.py"
[[ -x "$helper" || -f "$helper" ]] || die "firmware helper missing: ${helper}"

need_cmd python3
ensure_dir "$out_dir" "$SPX_LOG_DIR/firmware"

tmp_out="${SPX_BUILD_DIR}/firmware-extract-tmp"
rm -rf "$tmp_out"
ensure_dir "$tmp_out"

info "Extracting firmware to ${out_dir}"
help_text="$(python3 "$helper" --help 2>&1 || true)"

if grep -q -- '--out\|-o' <<< "$help_text"; then
  run_logged "${SPX_LOG_DIR}/firmware/extract.log" \
    python3 "$helper" -w "$windows_root" -o "$tmp_out"
else
  run_logged "${SPX_LOG_DIR}/firmware/extract.log" \
    bash -c 'cd "$1" && python3 scripts/getfw.py -w "$2"' _ "$firmware_repo" "$windows_root"
  if [[ -d "${firmware_repo}/out" ]]; then
    cp -a "${firmware_repo}/out/." "$tmp_out/"
  else
    die "firmware helper did not create expected ${firmware_repo}/out"
  fi
fi

rm -rf "$out_dir"
ensure_dir "$out_dir"
cp -a "${tmp_out}/." "$out_dir/"

"${SCRIPT_DIR}/validate-firmware.sh" "$out_dir"
info "Firmware tree is staged at ${out_dir}"
