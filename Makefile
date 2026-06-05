.PHONY: help check-host docs-check fetch-upstreams kernel firmware validate-firmware \
	grub boot-tree qemu-smoke hardware-logs fedora-packages ubuntu-packages \
	fedora-image ubuntu-image qemu-iso-smoke container-shell \
	kernel-install-artifacts fedora-live-spx arch-spx-image qemu-iso-smoke-spx

help:
	@printf '%s\n' 'Surface Pro X Linux docs repo'
	@printf '%s\n' ''
	@printf '%s\n' 'Core targets:'
	@printf '%s\n' '  check-host        Check local dependencies'
	@printf '%s\n' '  fetch-upstreams   Clone/update upstream source repos'
	@printf '%s\n' '  kernel            Build Surface Pro X kernel artifacts'
	@printf '%s\n' '  firmware          Extract firmware from Windows recovery material'
	@printf '%s\n' '  validate-firmware Validate staged firmware files'
	@printf '%s\n' '  grub              Build AArch64 GRUB bootaa64.efi'
	@printf '%s\n' '  boot-tree         Create EFI boot tree; pass DTB=/path/to/file.dtb'
	@printf '%s\n' '  qemu-smoke        Run generic ARM64 QEMU smoke; pass IMAGE=/path/to/image'
	@printf '%s\n' '  qemu-iso-smoke    Run generic ARM64 ISO boot smoke; pass ISO=/path/to/file.iso'
	@printf '%s\n' '  hardware-logs     Collect logs on the physical Surface Pro X'
	@printf '%s\n' '  fedora-packages   Build starter Fedora toolkit RPM'
	@printf '%s\n' '  ubuntu-packages   Build starter Ubuntu toolkit DEB'
	@printf '%s\n' '  fedora-image      Copy/customize Fedora ARM64 image; pass BASE_IMAGE=...'
	@printf '%s\n' '  ubuntu-image      Copy/customize Ubuntu ARM64 image; pass BASE_IMAGE=...'
	@printf '%s\n' '  arch-spx-image    Build Arch Linux ARM SPX image'
	@printf '%s\n' '  container-shell   Open the Fedora toolchain container'

docs-check:
	@find README.md containers docs scripts tests -name '*.md' -print | sort

check-host:
	@scripts/check-host.sh

fetch-upstreams:
	@scripts/fetch-upstreams.sh

kernel:
	@scripts/build-kernel.sh

firmware:
	@scripts/extract-firmware.sh

validate-firmware:
	@scripts/validate-firmware.sh $${FIRMWARE_ROOT:-}

grub:
	@scripts/build-grub.sh

boot-tree:
	@test -n "$${DTB:-}" || { printf '%s\n' 'DTB=/path/to/surface-pro-x.dtb is required'; exit 1; }
	@if [ -n "$${INITRAMFS:-}" ]; then \
		scripts/create-boot-tree.sh --dtb "$${DTB}" --initramfs "$${INITRAMFS}"; \
	else \
		scripts/create-boot-tree.sh --dtb "$${DTB}"; \
	fi

qemu-smoke:
	@test -n "$${IMAGE:-}" || { printf '%s\n' 'IMAGE=/path/to/image is required'; exit 1; }
	@scripts/qemu-smoke.sh --image "$${IMAGE}"

qemu-iso-smoke:
	@test -n "$${ISO:-}" || { printf '%s\n' 'ISO=/path/to/aarch64.iso is required'; exit 1; }
	@bash scripts/qemu-iso-smoke.sh --iso "$${ISO}"

hardware-logs:
	@scripts/collect-hardware-logs.sh

fedora-packages:
	@scripts/build-fedora-packages.sh

ubuntu-packages:
	@scripts/build-ubuntu-packages.sh

fedora-image:
	@test -n "$${BASE_IMAGE:-}" || { printf '%s\n' 'BASE_IMAGE=/path/to/fedora-aarch64.img is required'; exit 1; }
	@if [ -n "$${TOOLKIT_RPM:-}" ]; then \
		scripts/make-fedora-image.sh --base-image "$${BASE_IMAGE}" --toolkit-rpm "$${TOOLKIT_RPM}"; \
	else \
		scripts/make-fedora-image.sh --base-image "$${BASE_IMAGE}"; \
	fi

ubuntu-image:
	@test -n "$${BASE_IMAGE:-}" || { printf '%s\n' 'BASE_IMAGE=/path/to/ubuntu-arm64.img is required'; exit 1; }
	@if [ -n "$${TOOLKIT_DEB:-}" ]; then \
		scripts/make-ubuntu-image.sh --base-image "$${BASE_IMAGE}" --toolkit-deb "$${TOOLKIT_DEB}"; \
	else \
		scripts/make-ubuntu-image.sh --base-image "$${BASE_IMAGE}"; \
	fi

container-shell:
	@scripts/container-shell.sh

kernel-install-artifacts:
	@bash scripts/install-kernel-artifacts.sh

# Remaster a Fedora AArch64 live ISO to use the surface kernel.
# Requires: ISO=/path/to/Fedora-*.aarch64.iso  (must be run as root)
fedora-live-spx:
	@test -n "$${ISO:-}" || { printf '%s\n' 'ISO=/path/to/Fedora-aarch64-live.iso is required'; exit 1; }
	@sudo bash scripts/remaster-fedora-live.sh --iso "$${ISO}"

arch-spx-image:
	@if [ -n "$${OUT:-}" ] && [ -n "$${WRITE:-}" ]; then \
		sudo bash scripts/build-arch-spx-image.sh --out "$${OUT}" --write "$${WRITE}"; \
	elif [ -n "$${OUT:-}" ]; then \
		sudo bash scripts/build-arch-spx-image.sh --out "$${OUT}"; \
	elif [ -n "$${WRITE:-}" ]; then \
		sudo bash scripts/build-arch-spx-image.sh --write "$${WRITE}"; \
	else \
		sudo bash scripts/build-arch-spx-image.sh; \
	fi

# QEMU smoke test of the remastered surface live ISO
qemu-iso-smoke-spx:
	@bash scripts/qemu-iso-smoke.sh \
		--iso "$${ISO:-build/artifacts/images/fedora-spx-live.iso}"
