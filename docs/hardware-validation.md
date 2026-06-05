# Hardware Validation

Physical hardware testing is mandatory. QEMU can only reduce iteration time for
generic image and boot errors.

## Device Requirements

Recommended test device:

- Surface Pro X SQ1 or SQ2
- Type Cover
- USB-C hub
- USB keyboard
- USB Ethernet adapter
- USB-C flash drive
- known-good Windows recovery image
- backup of existing data

## Safety Rules

- Start with USB boot only.
- Do not write to internal NVMe until USB boot is reliable.
- Keep Windows recovery media available.
- Record firmware versions before testing.
- Collect logs after every boot attempt.
- Keep Secure Boot off until the unsigned boot path is stable.

## Phase A: USB Boot

Pass criteria:

- device enters GRUB
- kernel starts
- initramfs loads
- USB host controllers initialize
- USB storage block device appears
- root filesystem mounts
- console or display manager appears
- logs can be collected

Data to collect:

```sh
dmesg
journalctl -b
lsblk
cat /proc/cmdline
find /sys/firmware/efi -maxdepth 2 -type d
```

Current Phase A status:

- GRUB: pass
- DTB kernel boot: pass
- initramfs start: pass
- xHCI/hub discovery: pass
- UAS/usb-storage registration: pass
- USB root block device: fail/current blocker
- root filesystem mount: blocked

Current diagnostic command set inside the Arch initramfs:

```sh
ls -l /dev/sd* /dev/disk/by-uuid /dev/disk/by-partuuid
dmesg | grep -Ei 'usb|xhci|dwc3|uas|storage|scsi|sd[a-z]|root|partuuid' | tail -120
```

The current default GRUB entry is `Arch SPX - DTB post-udev diagnostic shell`.
It is expected to stop before root mount so USB/storage state can be inspected.

## Phase B: Basic Platform

Pass criteria:

- Type Cover keyboard works
- Type Cover touchpad works
- power and volume buttons work
- battery status appears
- charger status appears
- thermal sensors appear
- RTC works

Data to collect:

```sh
lsmod
upower -d
sensors
timedatectl
libinput list-devices
```

## Phase C: Storage

Pass criteria:

- internal NVMe is detected
- no PCIe resource errors block NVMe
- read tests pass
- install-to-NVMe plan is reviewed before writing

Data to collect:

```sh
lspci -nn
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
dmesg | grep -Ei "nvme|pcie|pci"
```

## Phase D: WiFi and Bluetooth

Pass criteria:

- firmware files are present
- `qrtr`, `pd-mapper`, `tqftpserv`, and `rmtfs` start
- WiFi interface appears
- NetworkManager can scan
- Bluetooth controller appears

Data to collect:

```sh
systemctl status qrtr pd-mapper tqftpserv rmtfs
ip link
nmcli dev wifi list
bluetoothctl list
dmesg | grep -Ei "ath10k|wcn3990|qca|qrtr|remoteproc|firmware"
```

## Phase E: GPU and Desktop

Pass criteria:

- display survives boot handoff
- DRM device appears
- Plasma Wayland or X11 session starts
- brightness control works
- no obvious GPU lockups under light desktop use

Data to collect:

```sh
ls /dev/dri
loginctl session-status
kscreen-doctor -o
dmesg | grep -Ei "drm|msm|adreno|a680|gpu|firmware"
```

## Phase F: Advanced Features

Features:

- touch
- pen
- suspend and resume
- audio
- cameras
- LTE modem
- external display
- GNSS/GPS

These are later milestones and should not block the first bootable images.

## Test Report Template

```text
Date:
Device:
SQ version:
Windows firmware version:
Image build:
Kernel commit:
Distro:
Boot mode:
Storage target:

Result:

Working:

Broken:

Logs attached:

Next action:
```
