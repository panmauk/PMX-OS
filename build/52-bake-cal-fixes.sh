#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"
INC=config/includes.chroot

echo "== /usr/lib/os-release -> PMX OS too (Calamares & others read this) =="
mkdir -p "$INC/usr/lib"
cp -f "$INC/etc/os-release" "$INC/usr/lib/os-release"

echo "== disable idle screen-lock in the live session (no password = lockout) =="
mkdir -p "$INC/etc/skel/.config"
cat > "$INC/etc/skel/.config/kscreenlockerrc" <<'EOF'
[Daemon]
Autolock=false
LockOnResume=false
Timeout=0

[Greeter][Wallpaper][org.kde.image][General]
Image=/usr/share/wallpapers/PanmoxOS/contents/images/1920x1080.png
EOF

echo "== rewrite Calamares hook with versionedName fix (the welcome-string cause) =="
cat > config/hooks/normal/0970-panmox-calamares.hook.chroot <<'EOF'
#!/bin/sh
[ -d /etc/calamares ] || exit 0
BR=/etc/calamares/branding
if [ -d "$BR/debian" ]; then rm -rf "$BR/panmox"; cp -r "$BR/debian" "$BR/panmox"; else mkdir -p "$BR/panmox"; fi
cp -f /usr/local/share/panmox/cal-welcome.png "$BR/panmox/welcome.png" 2>/dev/null || true
cp -f /usr/local/share/panmox/cal-welcome.png "$BR/panmox/slide1.png" 2>/dev/null || true
cp -f /usr/local/share/panmox/calamares-logo.png "$BR/panmox/debian-logo.png" 2>/dev/null || true
cp -f /usr/local/share/panmox/calamares-logo.png "$BR/panmox/" 2>/dev/null || true
[ -f "$BR/panmox/show.qml" ] && sed -i 's/Debian GNU\/Linux/PMX OS/g; s/Debian/PMX OS/g' "$BR/panmox/show.qml"
D="$BR/panmox/branding.desc"
if [ -f "$D" ]; then
  if grep -q '^componentName:' "$D"; then sed -i 's/^componentName:.*/componentName:  panmox/' "$D"; else sed -i '1i componentName:  panmox' "$D"; fi
  sed -i 's#^\(\s*welcomeStyleCalamares:\).*#\1 false#' "$D"
  sed -i 's#^\(\s*productName:\).*#\1 "PMX OS"#' "$D"
  sed -i 's#^\(\s*shortProductName:\).*#\1 "PMX OS"#' "$D"
  sed -i 's#^\(\s*versionedName:\).*#\1 "PMX OS 0.1 (Phosphor)"#' "$D"
  sed -i 's#^\(\s*shortVersionedName:\).*#\1 "PMX OS 0.1"#' "$D"
  sed -i 's#^\(\s*version:\).*#\1 "0.1 Phosphor"#' "$D"
  sed -i 's#^\(\s*shortVersion:\).*#\1 "0.1"#' "$D"
  sed -i 's#^\(\s*productUrl:\).*#\1 "https://panmox.org/"#' "$D"
  sed -i 's#^\(\s*supportUrl:\).*#\1 "https://panmox.org/"#' "$D"
  sed -i 's#^\(\s*bootloaderEntryName:\).*#\1 "PMX OS"#' "$D"
  sed -i 's#^\(\s*productLogo:\).*#\1 "calamares-logo.png"#' "$D"
  sed -i 's#^\(\s*productIcon:\).*#\1 "calamares-logo.png"#' "$D"
  sed -i 's#^\(\s*productWelcome:\).*#\1 "welcome.png"#' "$D"
fi
[ -f /etc/calamares/settings.conf ] && sed -i 's#^\(\s*-\?\s*branding:\s*\).*#\1panmox#' /etc/calamares/settings.conf 2>/dev/null || true
for w in /etc/calamares/modules/welcome*.conf; do
  [ -f "$w" ] && sed -i 's/Debian GNU\/Linux/PMX OS/g; s/Debian 12 (bookworm)/PMX OS 0.1/g' "$w" 2>/dev/null || true
done
for f in /usr/share/applications/*calamares*.desktop /usr/share/applications/install-debian.desktop; do
  [ -f "$f" ] || continue
  sed -i 's/^Name=.*/Name=Install PMX OS/' "$f" 2>/dev/null || true
  sed -i 's/^Comment=.*/Comment=Install PMX OS to your disk/' "$f" 2>/dev/null || true
done
exit 0
EOF
chmod +x config/hooks/normal/0970-panmox-calamares.hook.chroot

echo "BAKE CAL FIXES DONE"
