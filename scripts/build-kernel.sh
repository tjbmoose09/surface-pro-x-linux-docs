#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

prepare_only=false
skip_fetch=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prepare-only)
      prepare_only=true
      shift
      ;;
    --skip-fetch)
      skip_fetch=true
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Usage: scripts/build-kernel.sh [--prepare-only] [--skip-fetch]

Builds the Surface Pro X ARM64 kernel using the configured linux-surface kernel
ref and Surface Pro X config fragment.

Environment:
  SPX_KERNEL_REF           Kernel ref to checkout, default from config/sources.env
  SPX_CROSS_COMPILE       Cross prefix, default aarch64-linux-gnu-
  SPX_KERNEL_BUILD_DIR    Out-of-tree kernel build dir
  SPX_KERNEL_ARTIFACT_DIR Output artifact dir
EOF
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

if [[ "$skip_fetch" == false ]]; then
  "${SCRIPT_DIR}/fetch-upstreams.sh" --only kernel
  "${SCRIPT_DIR}/fetch-upstreams.sh" --only aarch64-kernel-configs
fi

kernel_dir="$(repo_path_for kernel)"
config_dir="$(repo_path_for aarch64-kernel-configs)"
surface_config="${config_dir}/fragments/spx.config"
override_config="${SPX_REPO_ROOT}/config/kernel/overrides.config"

[[ -d "${kernel_dir}/.git" ]] || die "kernel source missing; run scripts/fetch-upstreams.sh --only kernel"
[[ -f "$surface_config" ]] || die "Surface Pro X config missing: ${surface_config}"
[[ -f "$override_config" ]] || die "override config missing: ${override_config}"

need_cmd make

make_args=(ARCH="$SPX_ARCH" O="$SPX_KERNEL_BUILD_DIR")

if [[ "$(uname -m)" != "aarch64" ]]; then
  if [[ -n "${SPX_CROSS_COMPILE:-}" && -x "$(command -v "${SPX_CROSS_COMPILE}gcc" || true)" ]]; then
    make_args+=(CROSS_COMPILE="$SPX_CROSS_COMPILE")
  elif have_cmd clang; then
    warn "GNU ARM64 cross compiler not found; using LLVM=1"
    make_args+=(LLVM=1)
  else
    die "no ARM64 compiler found; install ${SPX_CROSS_COMPILE}gcc or clang"
  fi
fi

ensure_dir "$SPX_KERNEL_BUILD_DIR" "$SPX_KERNEL_ARTIFACT_DIR" "$SPX_LOG_DIR/kernel"

info "Preparing kernel config in ${SPX_KERNEL_BUILD_DIR}"
run_logged "${SPX_LOG_DIR}/kernel/defconfig.log" \
  make -C "$kernel_dir" "${make_args[@]}" defconfig

run_logged "${SPX_LOG_DIR}/kernel/merge-config.log" \
  "${kernel_dir}/scripts/kconfig/merge_config.sh" \
    -m \
    -O "$SPX_KERNEL_BUILD_DIR" \
    "${SPX_KERNEL_BUILD_DIR}/.config" \
    "$surface_config" \
    "$override_config"

run_logged "${SPX_LOG_DIR}/kernel/olddefconfig.log" \
  make -C "$kernel_dir" "${make_args[@]}" olddefconfig

if [[ "$prepare_only" == true ]]; then
  info "Kernel config prepared; stopping before build"
  exit 0
fi

info "Building kernel Image, modules, and DTBs"
run_logged "${SPX_LOG_DIR}/kernel/build.log" \
  make -C "$kernel_dir" "${make_args[@]}" Image modules dtbs

info "Installing kernel artifacts to ${SPX_KERNEL_ARTIFACT_DIR}"
ensure_dir "${SPX_KERNEL_ARTIFACT_DIR}/modules" "${SPX_KERNEL_ARTIFACT_DIR}/dtbs"

run_logged "${SPX_LOG_DIR}/kernel/modules-install.log" \
  make -C "$kernel_dir" "${make_args[@]}" \
    INSTALL_MOD_PATH="${SPX_KERNEL_ARTIFACT_DIR}/modules" modules_install

run_logged "${SPX_LOG_DIR}/kernel/dtbs-install.log" \
  make -C "$kernel_dir" "${make_args[@]}" \
    INSTALL_DTBS_PATH="${SPX_KERNEL_ARTIFACT_DIR}/dtbs" dtbs_install

cp "${SPX_KERNEL_BUILD_DIR}/arch/arm64/boot/Image" "${SPX_KERNEL_ARTIFACT_DIR}/Image"
cp "${SPX_KERNEL_BUILD_DIR}/.config" "${SPX_KERNEL_ARTIFACT_DIR}/config"

{
  printf 'kernel_repo=%s\n' "$SPX_KERNEL_REPO"
  printf 'kernel_ref=%s\n' "$SPX_KERNEL_REF"
  printf 'kernel_commit=%s\n' "$(git_head "$kernel_dir")"
  printf 'config_repo=%s\n' "$SPX_CONFIG_REPO"
  printf 'config_ref=%s\n' "$SPX_CONFIG_REF"
  printf 'config_commit=%s\n' "$(git_head "$config_dir")"
  printf 'built_at=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
} > "${SPX_KERNEL_ARTIFACT_DIR}/manifest.env"

info "Kernel artifacts are in ${SPX_KERNEL_ARTIFACT_DIR}"
