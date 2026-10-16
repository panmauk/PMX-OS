#!/usr/bin/env bash
set -uo pipefail
ISO="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"/live-image-amd64.hybrid.iso
OVMF_CODE=$(ls /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd 2>/dev/null | head -1)
OVMF_VARS=$(ls /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd 2>/dev/null | head -1)
echo "ISO=$ISO"; echo "OVMF_CODE=$OVMF_CODE"; echo "OVMF_VARS=$OVMF_VARS"
[ -f "$ISO" ] || { echo "NO ISO"; exit 1; }
cp -f "$OVMF_VARS" /tmp/pmx-OVMF_VARS.fd

command -v python3 >/dev/null 2>&1 || { apt-get update -qq && apt-get install -y --no-install-recommends python3; }

rm -f /tmp/pmx-qmp.sock /tmp/pmx-shot-*.png /tmp/pmx-qemu.log
ACCEL=tcg; CPU=qemu64
if [ -w /dev/kvm ]; then ACCEL=kvm; CPU=host; fi
echo "accel=$ACCEL cpu=$CPU"

# Launch QEMU under UEFI (OVMF), headless with a QMP control socket.
qemu-system-x86_64 \
  -name PanmoxOS \
  -machine q35,accel=$ACCEL \
  -cpu $CPU \
  -smp 4 -m 4096 \
  -drive if=pflash,format=raw,unit=0,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,unit=1,file=/tmp/pmx-OVMF_VARS.fd \
  -drive file="$ISO",media=cdrom,readonly=on \
  -vga std -display none \
  -qmp unix:/tmp/pmx-qmp.sock,server,nowait \
  >/tmp/pmx-qemu.log 2>&1 &
QPID=$!
echo "$QPID" > /tmp/pmx-qemu.pid
echo "qemu pid=$QPID"

cat > /tmp/pmx_shot.py <<'PY'
import socket, json, os, time
sock="/tmp/pmx-qmp.sock"
def conn():
    for _ in range(60):
        if os.path.exists(sock):
            try:
                s=socket.socket(socket.AF_UNIX); s.connect(sock); return s
            except OSError: pass
        time.sleep(0.5)
    raise SystemExit("qmp socket never appeared (qemu likely failed to start)")
s=conn(); f=s.makefile('rw')
f.readline()  # QMP greeting
def cmd(c,a=None):
    o={"execute":c}
    if a: o["arguments"]=a
    f.write(json.dumps(o)+"\n"); f.flush()
    while True:
        line=f.readline()
        if not line: raise SystemExit("qmp connection closed")
        m=json.loads(line)
        if "return" in m or "error" in m: return m
cmd("qmp_capabilities")
for i,dt in enumerate([45,30,35,40],1):  # screenshots at ~45,75,110,150s
    time.sleep(dt)
    p="/tmp/pmx-shot-%d.png"%i
    try:
        r=cmd("screendump",{"filename":p,"format":"png"})
    except Exception as e:
        r={"error":str(e)}
    print("shot",i,"t~",sum([45,30,35,40][:i]),"->",p,r)
cmd("quit")
PY
python3 /tmp/pmx_shot.py

echo "== shots =="
ls -l /tmp/pmx-shot-*.png 2>/dev/null && file /tmp/pmx-shot-*.png 2>/dev/null || echo "no shots"
DEST=/mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots
mkdir -p "$DEST" && cp -f /tmp/pmx-shot-*.png "$DEST/" 2>/dev/null && echo "copied shots -> $DEST"
echo "== qemu log tail =="
tail -n 25 /tmp/pmx-qemu.log
echo "BOOTSHOT DONE"
