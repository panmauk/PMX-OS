#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "== installing QEMU + OVMF (UEFI firmware) for boot testing =="
apt-get update -qq
apt-get install -y --no-install-recommends qemu-system-x86 qemu-utils ovmf
# GTK display backend (to show the VM window via WSLg); best-effort
apt-get install -y --no-install-recommends qemu-system-gui 2>/dev/null || echo "  (qemu-system-gui not separate on this release; gtk likely bundled)"

echo "== fetching Debian bookworm's own live-build (replaces Ubuntu's stale 3.0~a57) =="
PKGS="http://deb.debian.org/debian/dists/bookworm/main/binary-amd64/Packages.gz"
curl -fsSL -o /tmp/bookworm-Packages.gz "$PKGS"
gunzip -f /tmp/bookworm-Packages.gz
fn="$(awk '/^Package: live-build$/{f=1} f&&/^Filename: /{print $2; exit}' /tmp/bookworm-Packages)"
echo "  bookworm live-build: $fn"
curl -fsSL -o /tmp/live-build-debian.deb "http://deb.debian.org/debian/$fn"
apt-get install -y --allow-downgrades /tmp/live-build-debian.deb

echo "== confirm new toolchain =="
echo -n "lb version now: "; lb --version
echo "-- bootloader option (want plural --bootloaders for BIOS+UEFI) --"
lb config --help 2>&1 | grep -iE 'bootloader' | head
echo -n "qemu: "; command -v qemu-system-x86_64 || echo missing
echo -n "ovmf code: "; ls /usr/share/OVMF/OVMF_CODE*.fd 2>/dev/null || ls /usr/share/OVMF/*.fd 2>/dev/null || echo "OVMF .fd not found"
echo "TOOLCHAIN OK"
