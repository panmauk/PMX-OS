#!/usr/bin/env bash
set -uo pipefail
echo "== WSLg / GUI =="
echo "DISPLAY=${DISPLAY:-<unset>}  WAYLAND=${WAYLAND_DISPLAY:-<unset>}"
[ -d /mnt/wslg ] && echo "WSLg: present (can show Linux GUI windows on Windows desktop)" || echo "WSLg: ABSENT"
echo "== virtualization / qemu / ovmf =="
for t in qemu-system-x86_64 qemu-img kvm; do
  command -v "$t" >/dev/null 2>&1 && echo "  $t: $(command -v "$t")" || echo "  $t: missing"
done
[ -e /dev/kvm ] && echo "  /dev/kvm: present (nested KVM accel available)" || echo "  /dev/kvm: absent (will use TCG / slower)"
echo "  ovmf (UEFI firmware) apt candidate: $(apt-cache policy ovmf 2>/dev/null | awk '/Candidate/{print $2}')"
echo "== live-build versions available =="
echo "  ubuntu live-build candidate: $(apt-cache policy live-build 2>/dev/null | awk '/Candidate/{print $2}')"
echo "== background ISO build still going? =="
if pgrep -af "lb_binary|lb build|mksquashfs|debootstrap" >/dev/null 2>&1; then
  pgrep -af "lb_|mksquashfs|debootstrap|apt-get" | head -5
else
  echo "  no live-build processes detected (may be done or between stages)"
fi
echo "  newest iso: $(ls -t "${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"/*.iso 2>/dev/null | head -1 || echo none-yet)"
echo "PROBE OK"
