#!/usr/bin/env bash
set -uo pipefail
ISO="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"/live-image-amd64.hybrid.iso
OVMF_CODE=$(ls /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd 2>/dev/null | head -1)
OVMF_VARS=$(ls /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd 2>/dev/null | head -1)
cp -f "$OVMF_VARS" /tmp/pmx-live-VARS.fd

# WSLg display (root needs these to reach Windows desktop)
export DISPLAY=:0
export GDK_BACKEND=x11
export XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir
echo "DISPLAY=$DISPLAY  X11 sock: $(ls /tmp/.X11-unix/ 2>/dev/null)"
echo "WSLg: $(ls -d /mnt/wslg 2>/dev/null || echo MISSING)"

ACCEL=tcg; CPU=qemu64; [ -w /dev/kvm ] && { ACCEL=kvm; CPU=host; }
echo "accel=$ACCEL — launching PanmoxOS window..."

exec qemu-system-x86_64 \
  -name "PanmoxOS — live" \
  -machine q35,accel=$ACCEL -cpu $CPU -smp 6 -m 6144 \
  -drive if=pflash,format=raw,unit=0,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,unit=1,file=/tmp/pmx-live-VARS.fd \
  -drive file="$ISO",media=cdrom,readonly=on \
  -vga std \
  -device qemu-xhci,id=xhci -device usb-tablet \
  -display gtk \
  -qmp unix:/tmp/pmx-live-qmp.sock,server,nowait
