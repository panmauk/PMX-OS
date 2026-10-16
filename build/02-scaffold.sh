#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# debootstrap needs the Debian archive keyring to verify a Debian (not Ubuntu) build
if ! dpkg -s debian-archive-keyring >/dev/null 2>&1; then
  echo "== installing debian-archive-keyring =="
  apt-get install -y --no-install-recommends debian-archive-keyring
fi

BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
echo "== (re)creating build tree at $BUILD =="
rm -rf "$BUILD"
mkdir -p "$BUILD"
cd "$BUILD"

echo "== lb config (Debian 12 bookworm, KDE, hybrid BIOS+UEFI) =="
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
  --bootappend-live "boot=live components quiet splash live-config.hostname=panmoxos live-config.username=panmox live-config.user-fullname=PANMOX"

echo "== writing package lists =="
PL=config/package-lists

cat > "$PL/live.list.chroot" <<'EOF'
live-boot
live-config
live-config-systemd
EOF

cat > "$PL/desktop.list.chroot" <<'EOF'
kde-plasma-desktop
sddm
plasma-nm
plasma-discover
konsole
dolphin
kate
ark
gwenview
okular
firefox-esr
xserver-xorg
xinit
EOF

cat > "$PL/firmware.list.chroot" <<'EOF'
firmware-linux
firmware-linux-nonfree
firmware-iwlwifi
firmware-realtek
firmware-atheros
firmware-misc-nonfree
EOF

cat > "$PL/tools.list.chroot" <<'EOF'
sudo
network-manager
curl
wget
nano
htop
git
EOF

echo "== writing branding (includes.chroot) =="
INC=config/includes.chroot
mkdir -p "$INC/etc"

cat > "$INC/etc/os-release" <<'EOF'
PRETTY_NAME="PanmoxOS 0.1 (Phosphor)"
NAME="PanmoxOS"
VERSION_ID="0.1"
VERSION="0.1 (Phosphor)"
VERSION_CODENAME=phosphor
ID=panmoxos
ID_LIKE=debian
HOME_URL="https://panmox.org/"
SUPPORT_URL="https://panmox.org/"
BUG_REPORT_URL="https://panmox.org/"
EOF

printf 'panmoxos\n' > "$INC/etc/hostname"

cat > "$INC/etc/issue" <<'EOF'
 ____                                 ___  ____
|  _ \ __ _ _ __  _ __ ___   _____  _/ _ \/ ___|
| |_) / _` | '_ \| '_ ` _ \ / _ \ \/ / | | \___ \
|  __/ (_| | | | | | | | | | (_) >  <| |_| |___) |
|_|   \__,_|_| |_|_| |_| |_|\___/_/\_\\___/|____/   0.1

Debian underneath. No telemetry. No cloud. No boss.

EOF

cat > "$INC/etc/motd" <<'EOF'

  PanmoxOS 0.1 (Phosphor) — the machine time forgot.
  https://panmox.org/

EOF

echo "== resulting config tree =="
find config/package-lists config/includes.chroot -type f | sort
echo "---"
echo "distribution: $(grep -E '^LB_DISTRIBUTION=' config/* -r 2>/dev/null | head -1)"
echo "SCAFFOLD OK at $BUILD"
