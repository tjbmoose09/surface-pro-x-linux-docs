#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

topdir="${SPX_BUILD_DIR}/rpmbuild"
spec="${SPX_REPO_ROOT}/packaging/fedora/surface-pro-x-toolkit.spec"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --topdir)
      topdir="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Usage: scripts/build-fedora-packages.sh [--topdir PATH]

Builds the starter noarch Fedora RPM for the docs/tooling repo. Kernel RPMs are
a later milestone after the kernel artifact flow is stable.
EOF
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

need_cmd rpmbuild
ensure_dir "$topdir/BUILD" "$topdir/RPMS" "$topdir/SOURCES" "$topdir/SPECS" "$topdir/SRPMS"

rpmbuild \
  --define "_topdir ${topdir}" \
  --define "spx_repo_root ${SPX_REPO_ROOT}" \
  -bb "$spec"

info "Fedora package output is under ${topdir}/RPMS"
