#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"

# rewrite the calamares hook with the componentName fix (and welcome-string rebrand)
cat > config/hooks/normal/0970-panmox-calamares.hook.chroot <<'EOF'
#!/bin/sh
[ -d /etc/calamares ] || exit 0
BR=/etc/calamares/branding
if [ -d "$BR/debian" ]; then rm -rf "$BR/panmox"; cp -r "$BR/debian" "$BR/panmox"; else mkdir -p "$BR/panmox"; fi
cp -f /usr/local/share/panmox/calamares-logo.png "$BR/panmox/" 2>/dev/null || true
D="$BR/panmox/branding.desc"
if [ -f "$D" ]; then
  # componentName MUST equal the directory name or calamares aborts
  if grep -q '^componentName:' "$D"; then sed -i 's/^componentName:.*/componentName:  panmox/' "$D"; else sed -i '1i componentName:  panmox' "$D"; fi
  sed -i 's#^\(\s*productName:\).*#\1 "PanmoxOS"#' "$D" 2>/dev/null || true
  sed -i 's#^\(\s*shortProductName:\).*#\1 "PanmoxOS"#' "$D" 2>/dev/null || true
  sed -i 's#^\(\s*version:\).*#\1 "0.1 Phosphor"#' "$D" 2>/dev/null || true
  sed -i 's#^\(\s*shortVersion:\).*#\1 "0.1"#' "$D" 2>/dev/null || true
  sed -i 's#^\(\s*productUrl:\).*#\1 "https://panmox.org/"#' "$D" 2>/dev/null || true
  sed -i 's#^\(\s*supportUrl:\).*#\1 "https://panmox.org/"#' "$D" 2>/dev/null || true
  sed -i 's#^\(\s*bootloaderEntryName:\).*#\1 "PanmoxOS"#' "$D" 2>/dev/null || true
  sed -i 's#^\(\s*productLogo:\).*#\1 "calamares-logo.png"#' "$D" 2>/dev/null || true
  sed -i 's#^\(\s*productIcon:\).*#\1 "calamares-logo.png"#' "$D" 2>/dev/null || true
  sed -i 's#^\(\s*productWelcome:\).*#\1 "calamares-logo.png"#' "$D" 2>/dev/null || true
fi
[ -f /etc/calamares/settings.conf ] && sed -i 's#^\(\s*-\?\s*branding:\s*\).*#\1panmox#' /etc/calamares/settings.conf 2>/dev/null || true
# welcome screen heading -> PanmoxOS (calamares-settings-debian hardcodes a string)
for w in /etc/calamares/modules/welcome*.conf; do
  [ -f "$w" ] && sed -i 's/Debian GNU\/Linux/PanmoxOS/g; s/Debian 12 (bookworm)/PanmoxOS 0.1/g; s/\bDebian\b/PanmoxOS/g' "$w" 2>/dev/null || true
done
for f in /usr/share/applications/*calamares*.desktop /usr/share/applications/install-debian.desktop; do
  [ -f "$f" ] || continue
  sed -i 's/^Name=.*/Name=Install PanmoxOS/' "$f" 2>/dev/null || true
  sed -i 's/^Comment=.*/Comment=Install PanmoxOS to your disk/' "$f" 2>/dev/null || true
done
exit 0
EOF
chmod +x config/hooks/normal/0970-panmox-calamares.hook.chroot
echo "CAL FIX BAKED"
