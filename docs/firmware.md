# Firmware Process

Firmware is one of the highest-risk parts of this project because some required
files are proprietary Microsoft or Qualcomm files.

## Policy

- Do not commit proprietary firmware into this repository.
- Do not redistribute firmware images until licensing is clear.
- Document extraction from a Windows installation or Surface recovery image.
- Keep generated firmware packages local or private unless redistribution is
  allowed.

## Source

Reference repository:

```text
https://github.com/linux-surface/aarch64-firmware
```

The helper script extracts firmware from:

- a mounted Windows installation, or
- an extracted Surface recovery image.

Expected local command shape:

```sh
./scripts/getfw.py -w /path/to/windows-root
```

## GPU Firmware

Expected paths include:

```text
/lib/firmware/qcom/a680_gmu.bin
/lib/firmware/qcom/a680_sqe.fw
/lib/firmware/qcom/msft/surface/pro-x-sq2/qcdxkmsuc8180.mbn
```

The `.mbn` file is expected to come from Windows. The `a680_*` files are handled
by the upstream firmware reference.

## WiFi Firmware

Expected paths include:

```text
/lib/firmware/ath10k/WCN3990/hw1.0/board-2.bin
/lib/firmware/ath10k/WCN3990/hw1.0/firmware-5.bin
/lib/firmware/qcom/msft/surface/pro-x-sq2/*.jsn
/lib/firmware/qcom/msft/surface/pro-x-sq2/*.mbn
```

The documented upstream process:

1. Extract base firmware from Windows.
2. Create `board-2.bin` from board data files.
3. Patch `firmware-5.bin` with the required ath10k feature flags.
4. Install the resulting tree into `/lib/firmware`.

## Bluetooth Firmware

Bluetooth mostly needs firmware symlink fixes because the module reports an
unexpected chip ID.

Expected theme:

```text
/lib/firmware/qca/crnv01.* -> /lib/firmware/qca/crnv21.*
```

## Qualcomm Remote Processor Services

WiFi depends on services that let Qualcomm remote processors request firmware
and protected-domain data:

- `qrtr`
- `pd-mapper`
- `tqftpserv`
- `rmtfs`

For Surface Pro X, early work uses dummy EFS files because the real EFS
partitions are not available through the current driver path.

## Validation

Firmware validation should check:

- required files exist
- symlinks resolve
- services are enabled
- services start
- `dmesg` shows no missing firmware for WCN3990, Adreno, or remote processors
- NetworkManager sees a WiFi interface after the services settle

Do not mark WiFi or GPU support validated from QEMU. Those need the real device.
