#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"
mkdir -p config/packages.chroot
URL="https://github.com/panmauk/AltNet-Studio/releases/download/v1.0/altnet-studio_1.0.0_amd64.deb"
DEB=config/packages.chroot/altnet-studio_1.0.0_amd64.deb

echo "== downloading AltNet Studio .deb =="
curl -fL --retry 3 -o "$DEB" "$URL"
ls -lh "$DEB"
echo "sha256: $(sha256sum "$DEB" | cut -d' ' -f1)"

echo "== control / metadata =="
dpkg-deb -I "$DEB" 2>/dev/null | sed -n '1,40p'

echo "== .desktop + binaries (for dock pinning) =="
dpkg-deb -c "$DEB" 2>/dev/null | grep -iE '\.desktop$|/bin/|/opt/|\.png$' | head -40
echo "FETCH DONE"
