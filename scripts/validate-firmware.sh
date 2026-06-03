#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

firmware_root="${1:-${SPX_FIRMWARE_OUT}}"
[[ -d "$firmware_root" ]] || die "firmware root does not exist: ${firmware_root}"

shopt -s nullglob

missing=()
warnings=()

require_file() {
  local rel="$1"
  if [[ ! -f "${firmware_root}/${rel}" ]]; then
    missing+=("$rel")
  fi
}

require_glob() {
  local pattern="$1"
  local matches=( "${firmware_root}"/$pattern )
  if ((${#matches[@]} == 0)); then
    missing+=("$pattern")
  fi
}

warn_glob() {
  local pattern="$1"
  local matches=( "${firmware_root}"/$pattern )
  if ((${#matches[@]} == 0)); then
    warnings+=("$pattern")
  fi
}

require_file "ath10k/WCN3990/hw1.0/board-2.bin"
require_file "ath10k/WCN3990/hw1.0/firmware-5.bin"
require_file "qcom/a680_gmu.bin"
require_file "qcom/a680_sqe.fw"
require_glob "qcom/msft/surface/pro-x*/*.mbn"
require_glob "qcom/msft/surface/pro-x*/*.jsn"

warn_glob "qca/crnv21.*"
warn_glob "qca/crnv01.*"

if ((${#warnings[@]} > 0)); then
  warn "Optional Bluetooth-related firmware patterns not found: ${warnings[*]}"
fi

if ((${#missing[@]} > 0)); then
  printf 'Missing required firmware entries under %s:\n' "$firmware_root" >&2
  printf '  %s\n' "${missing[@]}" >&2
  exit 1
fi

info "Firmware validation passed for ${firmware_root}"
