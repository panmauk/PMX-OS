#!/usr/bin/env bash
set -uo pipefail
ISO="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"/live-image-amd64.hybrid.iso
OVMF_CODE=$(ls /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd 2>/dev/null | head -1)
OVMF_VARS=$(ls /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd 2>/dev/null | head -1)
cp -f "$OVMF_VARS" /tmp/pmx-OVMF_VARS.fd
rm -f /tmp/pmx-qmp.sock /tmp/pmx-c-shot-*.png /tmp/pmx-qemu.log
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

cat > /tmp/pmx_c.py <<'PY'
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
    p="/tmp/pmx-c-shot-%d.png"%n
    try: r=cmd("screendump",{"filename":p,"format":"png"})
    except Exception as e: r={"error":str(e)}
    print("shot",n,"->",p,r)
cmd("qmp_capabilities")
time.sleep(6); cmd("send-key",{"keys":[{"type":"qcode","data":"ret"}]})
for n,dt in enumerate([54,40,40,40],1):   # ~60,100,140,180s
    time.sleep(dt); shot(n)
cmd("quit")
PY
python3 /tmp/pmx_c.py
echo "== shots =="; ls -l /tmp/pmx-c-shot-*.png 2>/dev/null
DEST=/mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots
mkdir -p "$DEST" && cp -f /tmp/pmx-c-shot-*.png "$DEST/" 2>/dev/null && echo "copied -> $DEST"
echo "DONE"
