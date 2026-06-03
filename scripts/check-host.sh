#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

strict=false
if [[ "${1:-}" == "--strict" ]]; then
  strict=true
fi

missing_required=()

check_required() {
  local cmd="$1"
  if have_cmd "$cmd"; then
    printf 'ok       %s\n' "$cmd"
  else
    printf 'missing  %s\n' "$cmd"
    missing_required+=("$cmd")
  fi
}

check_optional() {
  local cmd="$1"
  local note="${2:-}"
  if have_cmd "$cmd"; then
    printf 'ok       %s\n' "$cmd"
  else
    if [[ -n "$note" ]]; then
      printf 'optional %s  %s\n' "$cmd" "$note"
    else
      printf 'optional %s\n' "$cmd"
    fi
  fi
}

info "Checking starter-tool dependencies"

check_required bash
check_required git
check_required make
check_required python3
check_required sed
check_required awk
check_required find
check_required xargs
check_required tar

check_optional jq "used for richer manifest checks"
check_optional rsync "used for boot-tree and image staging"
check_optional timeout "used by qemu-smoke"
check_optional qemu-system-aarch64 "needed for generic ARM64 smoke tests"
check_optional qemu-img "needed for image conversion/copying"
check_optional virt-customize "useful for distro image modification"
check_optional aarch64-linux-gnu-gcc "GNU ARM64 cross compiler"
check_optional clang "fallback compiler for LLVM kernel builds"
check_optional dtc "device tree compiler"
check_optional rpmbuild "needed for Fedora package output"
check_optional dpkg-deb "needed for Ubuntu package output"
check_optional podman "containerized builds"
check_optional docker "containerized builds"

if ((${#missing_required[@]} > 0)); then
  warn "Missing required tools: ${missing_required[*]}"
  if [[ "$strict" == true ]]; then
    exit 1
  fi
fi

info "Host check complete"
