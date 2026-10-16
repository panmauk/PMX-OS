#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"
INC=config/includes.chroot
A="${PMXOS_ASSETS_DIR:?Set PMXOS_ASSETS_DIR}"
IM=magick; command -v magick >/dev/null 2>&1 || IM=convert
FONT=/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf

echo "== green phosphor wallpaper =="
W=1920; H=1080; cx=$((W/2)); gy=$((H*70/100))
$IM -size ${W}x${H} gradient:'#04100A'-'#06160E' "$A/_pb.png"
$IM -size ${W}x${H} xc:black -fill '#15A06A' -draw "circle ${cx},${gy} ${cx},$(( gy - H*27/100 ))" -blur 0x$((W/12)) "$A/_pg.png"
$IM "$A/_pb.png" "$A/_pg.png" -compose screen -composite "$A/_pb.png"
$IM -size ${W}x${H} xc:black -fill '#3CFFB0' -draw "circle ${cx},${gy} ${cx},$(( gy - H*6/100 ))" -blur 0x$((W/26)) "$A/_pg2.png"
$IM "$A/_pb.png" "$A/_pg2.png" -compose screen -composite "$A/_pb.png"
$IM "$A/_pb.png" \( -size ${W}x${H} radial-gradient:'#ffffff'-'#06140D' \) -compose multiply -composite "$A/_pb.png"
WP="$INC/usr/share/wallpapers/PMXPhosphor"; mkdir -p "$WP/contents/images"
$IM "$A/_pb.png" -gravity south -font "$FONT" -pointsize $((H/30)) -fill '#8BFFD0' -annotate +0+$((H/14)) 'P A N M O X' "$WP/contents/images/1920x1080.png"
cp -f "$WP/contents/images/1920x1080.png" "$WP/contents/screenshot.png"
rm -f "$A"/_p*.png
cat > "$WP/metadata.desktop" <<'EOF'
[Desktop Entry]
Name=PMX Phosphor
X-KDE-PluginInfo-Name=PMXPhosphor
[Wallpaper]
defaultWidth=1920
defaultHeight=1080
EOF

echo "== green panel-background svg =="
cat > "$INC/usr/local/share/panmox/panel-background-green.svg" <<'EOF'
<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg" width="60" height="60" viewBox="0 0 60 60">
<rect id="topleft" x="0" y="0" width="6" height="6" fill="#1B6B47"/>
<rect id="top" x="6" y="0" width="48" height="6" fill="#1B6B47"/>
<rect id="topright" x="54" y="0" width="6" height="6" fill="#1B6B47"/>
<rect id="left" x="0" y="6" width="6" height="48" fill="#082A1C"/>
<rect id="center" x="6" y="6" width="48" height="48" fill="#082A1C"/>
<rect id="right" x="54" y="6" width="6" height="48" fill="#082A1C"/>
<rect id="bottomleft" x="0" y="54" width="6" height="6" fill="#05160E"/>
<rect id="bottom" x="6" y="54" width="48" height="6" fill="#05160E"/>
<rect id="bottomright" x="54" y="54" width="6" height="6" fill="#05160E"/>
</svg>
EOF

echo "== green color scheme =="
cat > "$INC/usr/share/color-schemes/PMXPhosphor.colors" <<'EOF'
[General]
Name=PMX Phosphor
ColorScheme=PMXPhosphor
accentActiveTitlebar=true
[Colors:Window]
BackgroundNormal=10,28,20
BackgroundAlternate=14,36,26
ForegroundNormal=210,255,235
ForegroundInactive=120,180,150
DecorationFocus=60,255,176
DecorationHover=60,255,176
[Colors:View]
BackgroundNormal=6,20,14
BackgroundAlternate=12,30,22
ForegroundNormal=210,255,235
ForegroundInactive=120,180,150
DecorationFocus=60,255,176
DecorationHover=60,255,176
[Colors:Button]
BackgroundNormal=16,44,32
BackgroundAlternate=22,56,40
ForegroundNormal=210,255,235
DecorationFocus=60,255,176
DecorationHover=60,255,176
[Colors:Selection]
BackgroundNormal=60,255,176
BackgroundAlternate=40,210,140
ForegroundNormal=4,16,10
ForegroundInactive=4,16,10
DecorationFocus=60,255,176
DecorationHover=60,255,176
[Colors:Header]
BackgroundNormal=14,42,30
BackgroundAlternate=10,30,22
ForegroundNormal=210,255,235
ForegroundInactive=120,180,150
DecorationFocus=60,255,176
[Colors:Tooltip]
BackgroundNormal=8,24,16
ForegroundNormal=210,255,235
[Colors:Complementary]
BackgroundNormal=6,20,14
ForegroundNormal=210,255,235
DecorationFocus=60,255,176
[WM]
activeBackground=14,52,36
activeForeground=215,255,238
activeBlend=60,255,176
inactiveBackground=10,26,18
inactiveForeground=110,160,135
EOF

echo "== rebuild plasma-theme hook: build BOTH PanmoxOS (blue) + PMXPhosphor (green) =="
cat > config/hooks/normal/0950-panmox-plasma-theme.hook.chroot <<'EOF'
#!/bin/sh
SRC=""
for c in /usr/share/plasma/desktoptheme/breeze-dark /usr/share/plasma/desktoptheme/default; do
  [ -d "$c" ] && SRC="$c" && break
done
[ -z "$SRC" ] && exit 0
build() {
  DST=/usr/share/plasma/desktoptheme/$1
  rm -rf "$DST"; cp -a "$SRC" "$DST"
  for d in widgets opaque/widgets translucent/widgets; do
    mkdir -p "$DST/$d"; cp "$2" "$DST/$d/panel-background.svg"; rm -f "$DST/$d/panel-background.svgz"
  done
  if [ -f "$DST/metadata.json" ]; then
    sed -i "s/\"Id\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"Id\": \"$1\"/" "$DST/metadata.json"
    sed -i "s/\"Name\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"Name\": \"$1\"/" "$DST/metadata.json"
  fi
}
build PanmoxOS   /usr/local/share/panmox/panel-background.svg
build PMXPhosphor /usr/local/share/panmox/panel-background-green.svg
exit 0
EOF
chmod +x config/hooks/normal/0950-panmox-plasma-theme.hook.chroot

echo "== toggle script + launcher =="
cat > "$INC/usr/local/bin/pmx-phosphor" <<'EOF'
#!/bin/sh
# Toggle PMX OS between Blue (default) and Phosphor (retro green)
STATE="$HOME/.config/panmox/.mode"
mkdir -p "$HOME/.config/panmox"
cur=$(cat "$STATE" 2>/dev/null || echo blue)
if [ "$cur" = "phosphor" ]; then
  plasma-apply-desktoptheme PanmoxOS 2>/dev/null
  plasma-apply-colorscheme PanmoxOS 2>/dev/null
  plasma-apply-wallpaperimage /usr/share/wallpapers/PanmoxOS/contents/images/1920x1080.png 2>/dev/null
  echo blue > "$STATE"
else
  plasma-apply-desktoptheme PMXPhosphor 2>/dev/null
  plasma-apply-colorscheme PMXPhosphor 2>/dev/null
  plasma-apply-wallpaperimage /usr/share/wallpapers/PMXPhosphor/contents/images/1920x1080.png 2>/dev/null
  echo phosphor > "$STATE"
fi
EOF
chmod +x "$INC/usr/local/bin/pmx-phosphor"
cat > "$INC/usr/share/applications/pmx-phosphor.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Phosphor Mode
GenericName=Retro theme toggle
Comment=Toggle PMX OS between Blue and retro Phosphor green
Exec=pmx-phosphor
Icon=preferences-desktop-color
Terminal=false
Categories=Settings;Utility;
EOF

echo "PHOSPHOR STAGED"
