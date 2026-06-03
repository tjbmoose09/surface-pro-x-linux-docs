.PHONY: help docs-check qemu-smoke kernel firmware fedora-image ubuntu-image

help:
	@printf '%s\n' 'Surface Pro X Linux docs repo'
	@printf '%s\n' ''
	@printf '%s\n' 'Targets planned for implementation:'
	@printf '%s\n' '  kernel        Build Surface Pro X kernel artifacts'
	@printf '%s\n' '  firmware      Extract and stage firmware from Windows recovery material'
	@printf '%s\n' '  fedora-image  Build Fedora KDE ARM64 image'
	@printf '%s\n' '  ubuntu-image  Build Ubuntu KDE ARM64 image'
	@printf '%s\n' '  qemu-smoke    Run generic ARM64 QEMU smoke tests'
	@printf '%s\n' ''
	@printf '%s\n' 'Current implemented target: docs-check'

docs-check:
	@find . -name '*.md' -print | sort

kernel:
	@printf '%s\n' 'Not implemented yet. See docs/build-pipeline.md'

firmware:
	@printf '%s\n' 'Not implemented yet. See docs/firmware.md'

fedora-image:
	@printf '%s\n' 'Not implemented yet. See docs/fedora-kde.md'

ubuntu-image:
	@printf '%s\n' 'Not implemented yet. See docs/ubuntu-kde.md'

qemu-smoke:
	@printf '%s\n' 'Not implemented yet. See docs/qemu-testing.md'
