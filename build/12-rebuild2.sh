#!/usr/bin/env bash
set -uo pipefail
cd "${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
echo "REBUILD2 START $(date -u +%FT%TZ)"

# clear chroot+binary so our branding gets rebuilt...
lb clean 2>&1 | tail -n 3
# ...then restore the config stamp (same flags as scaffold; preserves our custom config/ files)
lb config \
  --mode debian \
  --distribution bookworm \
  --archive-areas "main contrib non-free non-free-firmware" \
  --debian-installer none \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --bootloaders "syslinux grub-efi" \
  --memtest none \
  --apt-recommends true \
  --mirror-bootstrap "http://deb.debian.org/debian/" \
  --mirror-chroot "http://deb.debian.org/debian/" \
  --mirror-binary "http://deb.debian.org/debian/" \
  --mirror-chroot-security "http://security.debian.org/debian-security" \
  --mirror-binary-security "http://security.debian.org/debian-security" \
  --iso-application "PMX OS" \
  --iso-volume "PMX OS 1" \
  --iso-preparer "PANMOX" \
  --iso-publisher "PANMOX https://panmox.org/" \
  --bootappend-live "boot=live components quiet splash live-config.hostname=pmxos live-config.username=panmox live-config.user-fullname=PANMOX" 2>&1 | tail -n 3

# sanity: our rebrand files still present?
echo "rebrand files: $(find config/bootloaders config/includes.chroot/usr/share/wallpapers config/package-lists/branding.list.chroot -type f 2>/dev/null | wc -l) present"

lb build 2>&1 | tee build.log
code=${PIPESTATUS[0]}
echo "REBUILD2 END $(date -u +%FT%TZ) exit=$code"
ls -lh "${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"/*.iso 2>/dev/null || echo "no ISO produced"
exit "$code"
