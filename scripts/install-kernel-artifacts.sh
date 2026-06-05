#!/usr/bin/env bash
# Copies built kernel Image, modules, and DTBs into build/artifacts/kernel/.
# Run after scripts/build-kernel.sh (or after the kernel build background job).

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

kbuild="${SPX_KERNEL_BUILD_DIR}"
out="${SPX_KERNEL_ARTIFACT_DIR}"
kernel_src="$(repo_path_for kernel)"

[[ -f "${kbuild}/arch/arm64/boot/Image" ]] || \
    die "kernel Image not found at ${kbuild}/arch/arm64/boot/Image — build kernel first"

KVER=$(cat "${kbuild}/include/config/kernel.release" 2>/dev/null || \
       make -C "$kernel_src" ARCH=arm64 O="$kbuild" -s kernelrelease)

info "Installing kernel artifacts for ${KVER} → ${out}"

ensure_dir "${out}/dtbs/qcom" "${out}/modules"

cp "${kbuild}/arch/arm64/boot/Image"  "${out}/Image"
cp "${kbuild}/.config"                "${out}/config"
echo "$KVER"                        > "${out}/kernel.release"

find "${kbuild}/arch/arm64/boot/dts/qcom" -name "sc8180x*.dtb" \
    -exec install -m 644 {} "${out}/dtbs/qcom/" \;

make -C "$kernel_src" \
    ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
    O="$kbuild" \
    INSTALL_MOD_PATH="${out}/modules" \
    INSTALL_MOD_STRIP=1 \
    modules_install \
    2>&1 | tee "${SPX_LOG_DIR}/kernel/modules-install.log"

{
    printf 'kernel_repo=%s\n'   "$SPX_KERNEL_REPO"
    printf 'kernel_ref=%s\n'    "$SPX_KERNEL_REF"
    printf 'kernel_ver=%s\n'    "$KVER"
    printf 'built_at=%s\n'      "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
} > "${out}/manifest.env"

info "Artifacts staged in ${out}"
info "  Image:   ${out}/Image"
info "  DTBs:    ${out}/dtbs/qcom/"
info "  Modules: ${out}/modules/lib/modules/${KVER}/"
