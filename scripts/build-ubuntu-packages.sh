#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

pkg_dir="${SPX_BUILD_DIR}/deb/surface-pro-x-toolkit"
out_dir="${SPX_BUILD_DIR}/deb/out"
version="0.1.0-1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      version="${2:-}"
      shift 2
      ;;
    --out)
      out_dir="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Usage: scripts/build-ubuntu-packages.sh [--version VERSION] [--out PATH]

Builds a starter noarch Debian package for the docs/tooling repo. Kernel DEBs
are a later milestone after the kernel artifact flow is stable.
EOF
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

need_cmd dpkg-deb
rm -rf "$pkg_dir"
ensure_dir "${pkg_dir}/DEBIAN" "${pkg_dir}/usr/share/surface-pro-x-linux-docs" "$out_dir"
chmod 0755 "$pkg_dir" "${pkg_dir}/DEBIAN" "${pkg_dir}/usr" "${pkg_dir}/usr/share" "${pkg_dir}/usr/share/surface-pro-x-linux-docs"

cat > "${pkg_dir}/DEBIAN/control" <<EOF
Package: surface-pro-x-toolkit
Version: ${version}
Section: admin
Priority: optional
Architecture: all
Maintainer: tjbmoose09 <tjbmoose09@users.noreply.github.com>
Description: Starter tooling for Surface Pro X Linux enablement
 Documentation and scripts for building and validating Linux images for the
 Microsoft Surface Pro X.
EOF

cp -a "${SPX_REPO_ROOT}/README.md" "${pkg_dir}/usr/share/surface-pro-x-linux-docs/"
cp -a "${SPX_REPO_ROOT}/LICENSE" "${pkg_dir}/usr/share/surface-pro-x-linux-docs/"
cp -a "${SPX_REPO_ROOT}/Makefile" "${pkg_dir}/usr/share/surface-pro-x-linux-docs/"
cp -a "${SPX_REPO_ROOT}/config" "${pkg_dir}/usr/share/surface-pro-x-linux-docs/"
cp -a "${SPX_REPO_ROOT}/docs" "${pkg_dir}/usr/share/surface-pro-x-linux-docs/"
cp -a "${SPX_REPO_ROOT}/scripts" "${pkg_dir}/usr/share/surface-pro-x-linux-docs/"
cp -a "${SPX_REPO_ROOT}/tests" "${pkg_dir}/usr/share/surface-pro-x-linux-docs/"

find "$pkg_dir" -type d -exec chmod 0755 {} +
find "$pkg_dir" -type f -exec chmod 0644 {} +
find "${pkg_dir}/usr/share/surface-pro-x-linux-docs/scripts" -type f -name '*.sh' -exec chmod 0755 {} +

dpkg-deb --root-owner-group --build "$pkg_dir" "${out_dir}/surface-pro-x-toolkit_${version}_all.deb"
info "Ubuntu package output is ${out_dir}/surface-pro-x-toolkit_${version}_all.deb"
