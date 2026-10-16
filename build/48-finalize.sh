#!/usr/bin/env bash
set -uo pipefail
echo "== quit VM =="
python3 - <<'PY' 2>/dev/null || true
import socket,json
try:
    s=socket.socket(socket.AF_UNIX); s.connect("/tmp/pmx-ssh-qmp.sock"); f=s.makefile("rw"); f.readline()
    f.write(json.dumps({"execute":"qmp_capabilities"})+"\n"); f.flush(); f.readline()
    f.write(json.dumps({"execute":"quit"})+"\n"); f.flush(); print("VM quit")
except Exception: print("no VM")
PY
rm -f /tmp/pmx-ssh-qmp.sock

SRC="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"/live-image-amd64.hybrid.iso
DST="/mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/PMX-OS-1-amd64.iso"
echo "== copy updated ISO -> $DST =="
cp -f "$SRC" "$DST"; sync
# remove old, superseded artifacts (PanmoxOS- and 0.1-Phosphor-named)
rm -f "/mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/PanmoxOS-0.1-Phosphor-amd64.iso" \
      "/mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/PanmoxOS-0.1-Phosphor-amd64.iso.sha256" \
      "/mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/PMX-OS-0.1-Phosphor-amd64.iso" \
      "/mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/PMX-OS-0.1-Phosphor-amd64.iso.sha256"
SUM=$(sha256sum "$SRC" | awk '{print $1}')
printf '%s  PMX-OS-1-amd64.iso\n' "$SUM" > "$DST.sha256"
ls -lh "$DST"
echo "sha256: $SUM"
echo "FINALIZE DONE"
