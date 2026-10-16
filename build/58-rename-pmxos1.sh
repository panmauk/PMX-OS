#!/usr/bin/env bash
# 58-rename-pmxos1: finish the rename to "PMX OS 1".
#   - drop the "Phosphor" codename / "0.1" version from the OS *name* (the green
#     Phosphor retro MODE feature is untouched)
#   - any remaining user-visible "PanmoxOS" -> "PMX OS" (internal theme/scheme
#     IDs and folder names stay "PanmoxOS"; users never see those)
#   - remove the "Debian-based" line from the boot splash, bump it to v1
# Idempotent. Run as root inside WSL.
set -uo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
INC="$BUILD/config/includes.chroot"
cd "$BUILD"

echo "== os-release (etc + usr/lib) -> PMX OS 1 =="
for OSR in "$INC/etc/os-release" "$INC/usr/lib/os-release"; do
  cat > "$OSR" <<'EOF'
PRETTY_NAME="PMX OS 1"
NAME="PMX OS"
VERSION_ID="1"
VERSION="1"
ID=pmxos
ID_LIKE=debian
HOME_URL="https://panmox.org/"
SUPPORT_URL="https://panmox.org/"
BUG_REPORT_URL="https://panmox.org/"
EOF
done

echo "== motd / issue =="
sed -i 's/PMX OS 0\.1 (Phosphor)/PMX OS 1/' "$INC/etc/motd"
sed -i 's#|____/   0\.1#|____/   1#' "$INC/etc/issue"

echo "== PMX Hub footer (keep 'Debian underneath' here; only the bootloader loses Debian) =="
sed -i 's#<div class="foot">.*</div>#<div class="foot">PMX OS 1 \&middot; Debian underneath \&middot; panmox.org</div>#' \
  "$INC/usr/share/panmox/hub/index.html"

echo "== boot menu titles (syslinux) PanmoxOS -> PMX OS =="
sed -i 's/^menu title PanmoxOS$/menu title PMX OS/' "$BUILD/config/bootloaders/syslinux_common/menu.cfg"
sed -i 's/Press ENTER to boot PanmoxOS/Press ENTER to boot PMX OS/' "$BUILD/config/bootloaders/syslinux_common/stdmenu.cfg"

echo "== KDE display names PanmoxOS -> PMX OS (IDs unchanged) =="
sed -i 's/^Name=PanmoxOS$/Name=PMX OS/' "$INC/usr/share/color-schemes/PanmoxOS.colors"
sed -i 's/^Name=PanmoxOS$/Name=PMX OS/' "$INC/etc/skel/.config/kdeglobals"
sed -i 's/^Name=PanmoxOS$/Name=PMX OS/' "$INC/usr/share/wallpapers/PanmoxOS/metadata.desktop"
sed -i 's/^Name=PanmoxOS$/Name=PMX OS/; s/^Description=PanmoxOS boot splash$/Description=PMX OS boot splash/' \
  "$INC/usr/share/plymouth/themes/panmox/panmox.plymouth"
LNF="$INC/usr/share/plasma/look-and-feel/org.panmox.desktop/metadata.json"
sed -i 's/"Name": "PanmoxOS"/"Name": "PMX OS"/; s/PanmoxOS custom desktop/PMX OS custom desktop/; s/"Version": "0\.1"/"Version": "1"/' "$LNF"

echo "== Calamares branding hook -> PMX OS 1 =="
H970="$BUILD/config/hooks/normal/0970-panmox-calamares.hook.chroot"
sed -i 's/PMX OS 0\.1 (Phosphor)/PMX OS 1/g; s/PMX OS 0\.1/PMX OS 1/g; s/"0\.1 Phosphor"/"1"/g; s/"0\.1"/"1"/g' "$H970"

echo "== Plasma desktop-theme hook: keep ID=PanmoxOS, show 'PMX OS' as the name =="
H950="$BUILD/config/hooks/normal/0950-panmox-plasma-theme.hook.chroot"
cat > "$H950" <<'EOF'
#!/bin/sh
SRC=""
for c in /usr/share/plasma/desktoptheme/breeze-dark /usr/share/plasma/desktoptheme/default; do
  [ -d "$c" ] && SRC="$c" && break
done
[ -z "$SRC" ] && exit 0
build() {
  # $1 = theme id / folder (must match plasmarc); $2 = panel svg; $3 = display name
  DST=/usr/share/plasma/desktoptheme/$1
  rm -rf "$DST"; cp -a "$SRC" "$DST"
  for d in widgets opaque/widgets translucent/widgets; do
    mkdir -p "$DST/$d"; cp "$2" "$DST/$d/panel-background.svg"; rm -f "$DST/$d/panel-background.svgz"
  done
  if [ -f "$DST/metadata.json" ]; then
    sed -i "s/\"Id\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"Id\": \"$1\"/" "$DST/metadata.json"
    sed -i "s/\"Name\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"Name\": \"$3\"/" "$DST/metadata.json"
  fi
}
build PanmoxOS    /usr/local/share/panmox/panel-background.svg       "PMX OS"
build PMXPhosphor /usr/local/share/panmox/panel-background-green.svg "PMX OS Phosphor"
exit 0
EOF

echo "== regenerate boot splash (drop 'Debian-based', bump to v1) =="
A="${PMXOS_ASSETS_DIR:?Set PMXOS_ASSETS_DIR}"
IM=magick; command -v magick >/dev/null 2>&1 || IM=convert
FONT=/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf
BASE_TOP='#06090F'; BASE_BOT='#0A1024'; GLOW='#0FA9CE'; INK='#EAF7FF'; CYAN='#7FE9FF'; PINK='#FF2D7E'
mkdir -p "$A"
gen_boot() { # W H out
  local W=$1 H=$2 out=$3 cx=$(( $1/2 )) gy=$(( $2*30/100 )) ps dot
  $IM -size ${W}x${H} gradient:${BASE_TOP}-${BASE_BOT} "$A/_bb.png"
  $IM -size ${W}x${H} xc:black -fill "$GLOW" -draw "circle ${cx},${gy} ${cx},$(( gy - H*22/100 ))" -blur 0x$(( W/14 )) "$A/_bg.png"
  $IM "$A/_bb.png" "$A/_bg.png" -compose screen -composite "$A/_bb.png"
  ps=$(( H/9 )); dot=$(( H/40 ))
  $IM "$A/_bb.png" -gravity north -font "$FONT" -pointsize ${ps} -fill "$INK" \
      -annotate +0+$(( H*9/100 )) 'PMX OS' \
      -gravity north -pointsize $(( H/26 )) -fill "$CYAN" \
      -annotate +0+$(( H*9/100 + ps + H/40 )) 'UEFI   -   v1' "$A/_bt.png"
  $IM "$A/_bt.png" -fill "$PINK" -draw "circle $(( cx + W*13/100 )),$(( H*9/100 + ps*70/100 )) $(( cx + W*13/100 + dot )),$(( H*9/100 + ps*70/100 ))" "$out"
}
gen_boot 800 600 "$A/boot_800.png"
rm -f "$A"/_*.png
b64=$(base64 -w0 "$A/boot_800.png")
{
  printf '%s' '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="800" height="600" viewBox="0 0 800 600">'
  printf '%s' "<image width=\"800\" height=\"600\" xlink:href=\"data:image/png;base64,$b64\"/>"
  printf '%s' '</svg>'
} > "$BUILD/config/bootloaders/syslinux_common/splash.svg"

echo "== verify: any stray 'PanmoxOS' / '0.1' / Phosphor-name / Debian-splash left? =="
echo "-- remaining visible PanmoxOS (Name= only) --"
grep -rIn '^Name=PanmoxOS' "$INC" 2>/dev/null || echo "  (none)"
echo "-- remaining 0.1 in name files --"
grep -rIn '0\.1' "$INC/etc/os-release" "$INC/usr/lib/os-release" "$INC/etc/motd" "$INC/etc/issue" 2>/dev/null || echo "  (none)"
echo "RENAME-PMXOS1 DONE"
