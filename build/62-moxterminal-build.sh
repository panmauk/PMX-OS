#!/usr/bin/env bash
# Build the MoxTerminal .deb from D:\software\PANMOX Terminal and drop it into
# config/packages.chroot so live-build preinstalls it. Run as root in WSL.
set -uo pipefail
SRC="/mnt/d/software/PANMOX Terminal"
WORK=/root/moxbuild
DEB_DEST="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"/config/packages.chroot
PL="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"/config/package-lists

echo "== ensure build tools =="
miss=""
for t in dpkg-buildpackage dh fakeroot; do command -v "$t" >/dev/null 2>&1 || miss=yes; done
if [ -n "$miss" ]; then
  apt-get update -qq || true
  apt-get install -y --no-install-recommends debhelper dpkg-dev fakeroot
fi

echo "== stage source on ext4, strip CRLF =="
rm -rf "$WORK"; mkdir -p "$WORK/src"
cp -a "$SRC/." "$WORK/src/"
find "$WORK/src" -type f \( -name '*.py' -o -name '*.sh' -o -name 'Makefile' -o -name '*.toml' \
     -o -name '*.desktop' -o -name '*.md' -o -path '*/debian/*' \) -exec sed -i 's/\r$//' {} +
chmod +x "$WORK/src/debian/rules"
# compat level is declared via debhelper-compat in control; drop the duplicate file
rm -f "$WORK/src/debian/compat"
# the Makefile (override_dh_auto_install) already installs everything; a second
# pass via debian/install makes dh_install choke ("File name too long") — drop it
rm -f "$WORK/src/debian/install"

echo "== dpkg-buildpackage =="
( cd "$WORK/src" && dpkg-buildpackage -us -uc -b ) 2>&1 | tail -n 25
DEB=$(ls -1t "$WORK"/moxterminal_*_all.deb 2>/dev/null | head -1)
echo "built: ${DEB:-<none>}"
[ -n "$DEB" ] || { echo "BUILD FAILED"; exit 1; }
mkdir -p "$DEB_DEST"
cp -f "$DEB" "$DEB_DEST/moxterminal_1.0.0_all.deb"

echo "== runtime deps package list (belt-and-suspenders) =="
mkdir -p "$PL"
cat > "$PL/moxterminal.list.chroot" <<'EOF'
python3-gi
gir1.2-gtk-3.0
gir1.2-vte-2.91
fonts-jetbrains-mono
EOF

echo "== contents check =="; dpkg-deb -c "$DEB_DEST/moxterminal_1.0.0_all.deb" | grep -E 'bin/moxterminal|applications/|moxterminal/.*\.py' | head
ls -l "$DEB_DEST/"
echo "MOX DEB DONE"
