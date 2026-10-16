#!/usr/bin/env bash
set -euo pipefail
echo "== identity =="
id
echo "== host distro =="
. /etc/os-release && echo "$PRETTY_NAME ($VERSION_CODENAME)"
echo "== live-build available in apt? =="
apt-cache policy live-build 2>/dev/null | grep -E "Candidate|Installed" || echo "live-build: not found in apt cache (apt update needed)"
echo "== key tools present? =="
for t in debootstrap mksquashfs xorriso mtools; do
  if command -v "$t" >/dev/null 2>&1; then echo "  $t: $(command -v "$t")"; else echo "  $t: MISSING"; fi
done
echo "== loop device support (needed for ISO) =="
if [ -e /dev/loop-control ]; then echo "  /dev/loop-control: present"; else echo "  /dev/loop-control: MISSING"; fi
echo "== build target dir =="
df -h /home | tail -1
echo "PROBE OK"
