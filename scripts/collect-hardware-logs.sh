#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

out_dir="${SPX_LOG_DIR}/hardware/$(date -u '+%Y%m%dT%H%M%SZ')"
sanitize=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      out_dir="${2:-}"
      shift 2
      ;;
    --no-sanitize)
      sanitize=false
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Usage: scripts/collect-hardware-logs.sh [--out PATH] [--no-sanitize]

Collects hardware logs from a booted Surface Pro X Linux session. Run on the
tablet after USB boot attempts.
EOF
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

ensure_dir "$out_dir"

capture() {
  local name="$1"
  shift
  {
    printf '$ %s\n\n' "$*"
    "$@"
  } > "${out_dir}/${name}.txt" 2>&1 || true
}

capture_shell() {
  local name="$1"
  local command="$2"
  {
    printf '$ %s\n\n' "$command"
    bash -lc "$command"
  } > "${out_dir}/${name}.txt" 2>&1 || true
}

capture uname uname -a
capture cmdline cat /proc/cmdline
capture os-release cat /etc/os-release
capture dmesg dmesg
capture journal journalctl -b --no-pager
capture lsblk lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,UUID,MOUNTPOINTS
capture lsmod lsmod
capture ip-link ip link
capture systemd-failed systemctl --failed --no-pager
capture_shell firmware-dirs 'find /lib/firmware -maxdepth 4 \( -path "*ath10k*" -o -path "*qcom*" -o -path "*qca*" \) -print | sort'
capture_shell qcom-services 'systemctl status qrtr pd-mapper tqftpserv rmtfs --no-pager'
capture_shell efi-tree 'find /sys/firmware/efi -maxdepth 2 -type d -print'
capture_shell drm 'ls -la /dev/dri 2>/dev/null'
capture_shell surface-modules 'lsmod | grep -Ei "surface|qcom|ath10k|msm|qrtr|remoteproc|spi_hid"'

if have_cmd lspci; then capture lspci lspci -nn; fi
if have_cmd lsusb; then capture lsusb lsusb; fi
if have_cmd upower; then capture upower upower -d; fi
if have_cmd sensors; then capture sensors sensors; fi
if have_cmd nmcli; then capture nmcli-devices nmcli device; fi
if have_cmd bluetoothctl; then capture bluetooth bluetoothctl list; fi
if have_cmd libinput; then capture libinput libinput list-devices; fi
if have_cmd kscreen-doctor; then capture kscreen kscreen-doctor -o; fi

if [[ "$sanitize" == true ]]; then
  find "$out_dir" -type f -name '*.txt' -print0 | xargs -0 sed -i -E \
    -e 's/([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}/XX:XX:XX:XX:XX:XX/g' \
    -e 's/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/<uuid>/g'
fi

tarball="${out_dir}.tar.gz"
tar -C "$(dirname "$out_dir")" -czf "$tarball" "$(basename "$out_dir")"

info "Hardware logs written to ${out_dir}"
info "Archive written to ${tarball}"
