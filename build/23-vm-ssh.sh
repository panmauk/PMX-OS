#!/usr/bin/env bash
set -uo pipefail
ISO="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"/live-image-amd64.hybrid.iso
OVMF_CODE=$(ls /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd 2>/dev/null | head -1)
OVMF_VARS=$(ls /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd 2>/dev/null | head -1)
cp -f "$OVMF_VARS" /tmp/pmx-ssh-VARS.fd
rm -f /tmp/pmx-ssh-qmp.sock
ACCEL=tcg; CPU=qemu64; [ -w /dev/kvm ] && { ACCEL=kvm; CPU=host; }

# headless, with user-net + ssh forward host:2222 -> guest:22, and QMP for screenshots
exec qemu-system-x86_64 \
  -name "PanmoxOS-ssh" -machine q35,accel=$ACCEL -cpu $CPU -smp 6 -m 6144 \
  -drive if=pflash,format=raw,unit=0,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,unit=1,file=/tmp/pmx-ssh-VARS.fd \
  -drive file="$ISO",media=cdrom,readonly=on \
  -netdev user,id=n0,hostfwd=tcp::2222-:22 -device virtio-net-pci,netdev=n0 \
  -vga std -display none \
  -qmp unix:/tmp/pmx-ssh-qmp.sock,server,nowait
