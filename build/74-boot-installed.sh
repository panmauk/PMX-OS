#!/usr/bin/env bash
# Boot the INSTALLED disk (no ISO), reusing the OVMF NVRAM that Calamares wrote.
set -uo pipefail
OVMF_CODE=$(ls /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd 2>/dev/null | head -1)
TGT=/root/pmx-target.qcow2
rm -f /tmp/pmx-ssh-qmp.sock
ACCEL=tcg; CPU=qemu64; [ -w /dev/kvm ] && { ACCEL=kvm; CPU=host; }
echo "booting INSTALLED disk (accel=$ACCEL, no ISO)"
exec qemu-system-x86_64 \
  -name "PMX-installed" \
  -machine q35,accel=$ACCEL -cpu $CPU -smp 6 -m 6144 \
  -drive if=pflash,format=raw,unit=0,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,unit=1,file=/root/pmx-inst-VARS.fd \
  -drive file="$TGT",if=none,id=disk0,format=qcow2 \
  -device virtio-blk-pci,drive=disk0 \
  -netdev user,id=n0,hostfwd=tcp::2222-:22 -device virtio-net-pci,netdev=n0 \
  -vga std \
  -device qemu-xhci,id=xhci -device usb-tablet \
  -display none \
  -qmp unix:/tmp/pmx-ssh-qmp.sock,server,nowait
