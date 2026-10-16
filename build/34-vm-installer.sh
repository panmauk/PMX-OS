#!/usr/bin/env bash
set -uo pipefail
ISO="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"/live-image-amd64.hybrid.iso
OVMF_CODE=$(ls /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd 2>/dev/null | head -1)
OVMF_VARS=$(ls /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd 2>/dev/null | head -1)
cp -f "$OVMF_VARS" /tmp/pmx-inst-VARS.fd

# fresh blank target disk for the installer
TGT=/tmp/pmx-target.qcow2
rm -f "$TGT"
qemu-img create -f qcow2 "$TGT" 20G >/dev/null
echo "target disk: $TGT (20G)"

export DISPLAY=:0
export GDK_BACKEND=x11
export XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir
ACCEL=tcg; CPU=qemu64; [ -w /dev/kvm ] && { ACCEL=kvm; CPU=host; }
echo "accel=$ACCEL — opening PanmoxOS installer VM (ssh :2222, blank disk attached)"

exec qemu-system-x86_64 \
  -name "PanmoxOS installer" \
  -machine q35,accel=$ACCEL -cpu $CPU -smp 6 -m 6144 \
  -drive if=pflash,format=raw,unit=0,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,unit=1,file=/tmp/pmx-inst-VARS.fd \
  -drive file="$ISO",media=cdrom,readonly=on \
  -drive file="$TGT",if=none,id=disk0,format=qcow2 \
  -device virtio-blk-pci,drive=disk0 \
  -netdev user,id=n0,hostfwd=tcp::2222-:22 -device virtio-net-pci,netdev=n0 \
  -vga std \
  -device qemu-xhci,id=xhci -device usb-tablet \
  -display gtk \
  -qmp unix:/tmp/pmx-ssh-qmp.sock,server,nowait
