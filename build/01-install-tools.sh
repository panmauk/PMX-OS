#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "== apt update =="
apt-get update -qq

echo "== installing build toolchain =="
apt-get install -y --no-install-recommends \
  live-build debootstrap mtools squashfs-tools xorriso \
  isolinux syslinux-common syslinux-utils \
  grub-pc-bin grub-efi-amd64-bin grub-efi-ia32-bin \
  dosfstools ca-certificates curl

echo "== versions =="
echo -n "live-build (lb): "; lb --version 2>/dev/null || echo "?"
echo -n "debootstrap:     "; debootstrap --version 2>/dev/null || echo "?"

echo "== live-build flavor check =="
# Debian's live-build ships these auto/ helper templates; Ubuntu's differs.
ls /usr/share/live/build/ 2>/dev/null | head || true
echo "---"
# Does debootstrap know the Debian 'bookworm' suite?
if [ -e /usr/share/debootstrap/scripts/bookworm ]; then
  echo "debootstrap bookworm script: present (can build Debian 12)"
else
  echo "debootstrap bookworm script: MISSING"
fi

echo "INSTALL OK"
