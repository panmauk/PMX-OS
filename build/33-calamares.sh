#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"
INC=config/includes.chroot
IM=magick; command -v magick >/dev/null 2>&1 || IM=convert
FONT=/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf

echo "== installer logo =="
mkdir -p "$INC/usr/local/share/panmox"
$IM -size 520x170 xc:none -gravity center -font "$FONT" -pointsize 86 \
   -fill '#EAF7FF' -annotate +0+0 'PanmoxOS' \
   -fill '#FF2D7E' -draw "circle 470,118 478,118" \
   "$INC/usr/local/share/panmox/calamares-logo.png"
echo "logo: $(ls -l "$INC/usr/local/share/panmox/calamares-logo.png" | awk '{print $5}') bytes"

echo "== calamares packages =="
cat > config/package-lists/calamares.list.chroot <<'EOF'
calamares
calamares-settings-debian
grub-efi-amd64
grub-efi-amd64-bin
grub-pc-bin
efibootmgr
os-prober
dosfstools
e2fsprogs
cryptsetup
lvm2
squashfs-tools
rsync
EOF

echo "== branding hook (tolerant; won't break build) =="
cat > config/hooks/normal/0970-panmox-calamares.hook.chroot <<'EOF'
#!/bin/sh
# rebrand calamares to PanmoxOS; never fail the build
[ -d /etc/calamares ] || exit 0
BR=/etc/calamares/branding
if [ -d "$BR/debian" ]; then
  rm -rf "$BR/panmox"; cp -r "$BR/debian" "$BR/panmox"
else
  mkdir -p "$BR/panmox"
fi
cp -f /usr/local/share/panmox/calamares-logo.png "$BR/panmox/" 2>/dev/null || true
D="$BR/panmox/branding.desc"
if [ -f "$D" ]; then
  sed -i 's#^\(\s*productName:\).*#\1 "PanmoxOS"#' "$D" 2>/dev/null || true
  sed -i 's#^\(\s*shortProductName:\).*#\1 "PanmoxOS"#' "$D" 2>/dev/null || true
  sed -i 's#^\(\s*version:\).*#\1 "0.1 Phosphor"#' "$D" 2>/dev/null || true
  sed -i 's#^\(\s*shortVersion:\).*#\1 "0.1"#' "$D" 2>/dev/null || true
  sed -i 's#^\(\s*productUrl:\).*#\1 "https://panmox.org/"#' "$D" 2>/dev/null || true
  sed -i 's#^\(\s*supportUrl:\).*#\1 "https://panmox.org/"#' "$D" 2>/dev/null || true
  sed -i 's#^\(\s*productLogo:\).*#\1 "calamares-logo.png"#' "$D" 2>/dev/null || true
  sed -i 's#^\(\s*productIcon:\).*#\1 "calamares-logo.png"#' "$D" 2>/dev/null || true
  sed -i 's#^\(\s*productWelcome:\).*#\1 "calamares-logo.png"#' "$D" 2>/dev/null || true
fi
# select our branding
if [ -f /etc/calamares/settings.conf ]; then
  sed -i 's#^\(\s*-\?\s*branding:\s*\).*#\1panmox#' /etc/calamares/settings.conf 2>/dev/null || true
fi
# rename installer launcher(s)
for f in /usr/share/applications/*calamares*.desktop /usr/share/applications/install-debian.desktop; do
  [ -f "$f" ] || continue
  sed -i 's/^Name=.*/Name=Install PanmoxOS/' "$f" 2>/dev/null || true
  sed -i 's/^Comment=.*/Comment=Install PanmoxOS to your disk/' "$f" 2>/dev/null || true
done
exit 0
EOF
chmod +x config/hooks/normal/0970-panmox-calamares.hook.chroot

echo "CALAMARES SETUP DONE"
