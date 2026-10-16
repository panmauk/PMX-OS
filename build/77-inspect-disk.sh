#!/usr/bin/env bash
# Stop the installed VM, mount its root partition read-only, and verify the
# GRUB background + avatar that the install actually produced.
set -uo pipefail
echo "== stop installed VM =="
pkill -f 'PMX-installed' 2>/dev/null; sleep 3
RM=/mnt/pmxroot; mkdir -p "$RM"
DISK=/root/pmx-target.qcow2
ROOTDEV=""; LOOP=""
modprobe nbd max_part=8 2>/dev/null || true
if [ -e /dev/nbd0 ]; then
  qemu-nbd --disconnect /dev/nbd0 2>/dev/null || true
  qemu-nbd --connect=/dev/nbd0 -r "$DISK" && sleep 1
  partprobe /dev/nbd0 2>/dev/null || true
  for p in /dev/nbd0p2 /dev/nbd0p3 /dev/nbd0p1; do
    blkid "$p" 2>/dev/null | grep -q 'TYPE="ext4"' && { ROOTDEV="$p"; break; }
  done
fi
if [ -z "$ROOTDEV" ]; then
  echo "== nbd unavailable -> raw convert + losetup =="
  qemu-img convert -f qcow2 -O raw "$DISK" /root/pmx-target.raw
  LOOP=$(losetup -fP --show /root/pmx-target.raw)
  partprobe "$LOOP" 2>/dev/null || true
  for p in ${LOOP}p2 ${LOOP}p3 ${LOOP}p1; do
    blkid "$p" 2>/dev/null | grep -q 'TYPE="ext4"' && { ROOTDEV="$p"; break; }
  done
fi
echo "rootdev=$ROOTDEV"
[ -n "$ROOTDEV" ] || { echo "NO ROOT PART FOUND"; exit 1; }
mount -o ro,noload "$ROOTDEV" "$RM" 2>/dev/null || mount -o ro,noload,force "$ROOTDEV" "$RM"
echo "=== os-release ==="; grep PRETTY "$RM/etc/os-release"
echo "=== grub.cfg background/theme lines ==="; grep -niE 'background_image|/usr/share/pmx/grub-bg|desktop-base|grub-16x9|set_background' "$RM/boot/grub/grub.cfg" | head
echo "=== /etc/default/grub.d/pmx-grub.cfg ==="; cat "$RM/etc/default/grub.d/pmx-grub.cfg" 2>/dev/null
echo "=== pmx grub bg present on target? ==="; ls -l "$RM/usr/share/pmx/grub-bg.png" 2>/dev/null
echo "=== avatar files ==="; ls -l "$RM/home/panmox/.face" "$RM/home/panmox/.face.icon" "$RM/etc/skel/.face" 2>/dev/null
echo "=== avatar md5: installed home vs staged source (should match) ==="
md5sum "$RM/home/panmox/.face" "$RM/etc/skel/.face" "${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"/config/includes.chroot/etc/skel/.face 2>/dev/null
cp -f "$RM/usr/share/pmx/grub-bg.png" /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/_installed-grub-bg.png 2>/dev/null || true
echo "== cleanup =="
umount "$RM" 2>/dev/null || true
[ -n "$LOOP" ] && { losetup -d "$LOOP" 2>/dev/null; rm -f /root/pmx-target.raw; }
qemu-nbd --disconnect /dev/nbd0 2>/dev/null || true
echo INSPECT DONE
