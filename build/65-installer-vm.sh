#!/usr/bin/env bash
# Headless installer VM: ISO + blank 20G target disk + QMP + ssh. Target disk
# and OVMF VARS live on /root so a /tmp wipe can't destroy the install.
set -uo pipefail
ISO="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"/live-image-amd64.hybrid.iso
OVMF_CODE=$(ls /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd 2>/dev/null | head -1)
OVMF_VARS=$(ls /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd 2>/dev/null | head -1)
cp -f "$OVMF_VARS" /root/pmx-inst-VARS.fd
TGT=/root/pmx-target.qcow2
rm -f "$TGT"; qemu-img create -f qcow2 "$TGT" 20G >/dev/null
rm -f /tmp/pmx-ssh-qmp.sock
ACCEL=tcg; CPU=qemu64; [ -w /dev/kvm ] && { ACCEL=kvm; CPU=host; }
echo "accel=$ACCEL installer VM up (ssh :2222, blank disk /root/pmx-target.qcow2)"
exec qemu-system-x86_64 \
  -name "PanmoxOS installer" \
  -machine q35,accel=$ACCEL -cpu $CPU -smp 6 -m 6144 \
  -drive if=pflash,format=raw,unit=0,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,unit=1,file=/root/pmx-inst-VARS.fd \
  -drive file="$ISO",media=cdrom,readonly=on \
  -drive file="$TGT",if=none,id=disk0,format=qcow2 \
  -device virtio-blk-pci,drive=disk0 \
  -netdev user,id=n0,hostfwd=tcp::2222-:22 -device virtio-net-pci,netdev=n0 \
  -vga std \
  -device qemu-xhci,id=xhci -device usb-tablet \
  -display none \
  -qmp unix:/tmp/pmx-ssh-qmp.sock,server,nowait
