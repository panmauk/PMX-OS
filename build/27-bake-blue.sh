#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"
INC=config/includes.chroot

echo "== refined blue panel svg (tested live) =="
mkdir -p "$INC/usr/local/share/panmox"
cat > "$INC/usr/local/share/panmox/panel-background.svg" <<'EOF'
<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg" width="60" height="60" viewBox="0 0 60 60">
<rect id="topleft" x="0" y="0" width="6" height="6" fill="#274C86"/>
<rect id="top" x="6" y="0" width="48" height="6" fill="#274C86"/>
<rect id="topright" x="54" y="0" width="6" height="6" fill="#274C86"/>
<rect id="left" x="0" y="6" width="6" height="48" fill="#152A57"/>
<rect id="center" x="6" y="6" width="48" height="48" fill="#152A57"/>
<rect id="right" x="54" y="6" width="6" height="48" fill="#152A57"/>
<rect id="bottomleft" x="0" y="54" width="6" height="6" fill="#101F40"/>
<rect id="bottom" x="6" y="54" width="48" height="6" fill="#101F40"/>
<rect id="bottomright" x="54" y="54" width="6" height="6" fill="#101F40"/>
</svg>
EOF

echo "== hook: CREATE panel-background in the theme (breeze-dark has none) =="
cat > config/hooks/normal/0950-panmox-plasma-theme.hook.chroot <<'EOF'
#!/bin/sh
SRC=""
for c in /usr/share/plasma/desktoptheme/breeze-dark /usr/share/plasma/desktoptheme/default; do
  [ -d "$c" ] && SRC="$c" && break
done
[ -z "$SRC" ] && exit 0
DST=/usr/share/plasma/desktoptheme/PanmoxOS
rm -rf "$DST"; cp -a "$SRC" "$DST"
# breeze-dark inherits its panel bg, so CREATE ours explicitly in every variant
for d in widgets opaque/widgets translucent/widgets; do
  mkdir -p "$DST/$d"
  cp /usr/local/share/panmox/panel-background.svg "$DST/$d/panel-background.svg"
  rm -f "$DST/$d/panel-background.svgz"
done
# make the theme identify as PanmoxOS so selecting it works
if [ -f "$DST/metadata.json" ]; then
  sed -i 's/"Id"[[:space:]]*:[[:space:]]*"[^"]*"/"Id": "PanmoxOS"/' "$DST/metadata.json"
  sed -i 's/"Name"[[:space:]]*:[[:space:]]*"[^"]*"/"Name": "PanmoxOS"/' "$DST/metadata.json"
fi
exit 0
EOF
chmod +x config/hooks/normal/0950-panmox-plasma-theme.hook.chroot

echo "BAKE BLUE DONE"
