#!/usr/bin/env bash
set -euo pipefail
SRC="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"/live-image-amd64.hybrid.iso
DST="/mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/PanmoxOS-0.1-Phosphor-amd64.iso"
echo "source: $(ls -lh "$SRC" | awk '{print $5}')"
echo "copying to Documents (this is ~2.1G over to NTFS)..."
cp -f "$SRC" "$DST"
sync
echo "== copied =="
ls -lh "$DST"
echo "== sha256 (verify after writing to USB) =="
sha256sum "$SRC" | awk '{print $1}'
SUM=$(sha256sum "$SRC" | awk '{print $1}')
printf '%s  PanmoxOS-0.1-Phosphor-amd64.iso\n' "$SUM" > "/mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/PanmoxOS-0.1-Phosphor-amd64.iso.sha256"
echo "wrote checksum file next to the iso"
echo "COPY DONE"
