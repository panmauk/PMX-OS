#!/usr/bin/env bash
set -uo pipefail
ISO="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"/live-image-amd64.hybrid.iso
OVMF_CODE=$(ls /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd 2>/dev/null | head -1)
OVMF_VARS=$(ls /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd 2>/dev/null | head -1)
cp -f "$OVMF_VARS" /tmp/pmx-OVMF_VARS.fd
rm -f /tmp/pmx-qmp.sock /tmp/pmx-r-shot-*.png /tmp/pmx-qemu.log
ACCEL=tcg; CPU=qemu64; [ -w /dev/kvm ] && { ACCEL=kvm; CPU=host; }

qemu-system-x86_64 \
  -name PanmoxOS -machine q35,accel=$ACCEL -cpu $CPU -smp 4 -m 4096 \
  -drive if=pflash,format=raw,unit=0,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,unit=1,file=/tmp/pmx-OVMF_VARS.fd \
  -drive file="$ISO",media=cdrom,readonly=on \
  -vga std -display none \
  -qmp unix:/tmp/pmx-qmp.sock,server,nowait \
  >/tmp/pmx-qemu.log 2>&1 &
echo "qemu pid=$!"

cat > /tmp/pmx_r.py <<'PY'
import socket, json, os, time
sock="/tmp/pmx-qmp.sock"
def conn():
    for _ in range(60):
        if os.path.exists(sock):
            try:
                s=socket.socket(socket.AF_UNIX); s.connect(sock); return s
            except OSError: pass
        time.sleep(0.5)
    raise SystemExit("qmp socket never appeared")
s=conn(); f=s.makefile('rw'); f.readline()
def cmd(c,a=None):
    o={"execute":c}
    if a: o["arguments"]=a
    f.write(json.dumps(o)+"\n"); f.flush()
    while True:
        line=f.readline()
        if not line: raise SystemExit("qmp closed")
        m=json.loads(line)
        if "return" in m or "error" in m: return m
def shot(n):
    p="/tmp/pmx-r-shot-%d.png"%n
    try: r=cmd("screendump",{"filename":p,"format":"png"})
    except Exception as e: r={"error":str(e)}
    print("shot",n,"->",p,r)
cmd("qmp_capabilities")
time.sleep(3);  shot(1)                                   # GRUB menu (rebranded)
time.sleep(3);  cmd("send-key",{"keys":[{"type":"qcode","data":"ret"}]})  # backup: nudge boot
time.sleep(39); shot(2)                                   # ~45s  plymouth/sddm
time.sleep(30); shot(3)                                   # ~75s  login/desktop
time.sleep(35); shot(4)                                   # ~110s desktop (theme applying)
time.sleep(30); shot(5)                                   # ~140s themed desktop
cmd("quit")
PY
python3 /tmp/pmx_r.py

echo "== shots =="; ls -l /tmp/pmx-r-shot-*.png 2>/dev/null
DEST=/mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots
mkdir -p "$DEST" && cp -f /tmp/pmx-r-shot-*.png "$DEST/" 2>/dev/null && echo "copied -> $DEST"
echo "DONE"
