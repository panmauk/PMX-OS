#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"
INC=config/includes.chroot
A="${PMXOS_ASSETS_DIR:?Set PMXOS_ASSETS_DIR}"
IM=magick; command -v magick >/dev/null 2>&1 || IM=convert
FONT=/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf
BASE_TOP='#06090F'; BASE_BOT='#0A1024'; GLOW='#0FA9CE'; INK='#EAF7FF'; CYAN='#7FE9FF'; PINK='#FF2D7E'

echo "== os-release / hostname / issue / motd -> PMX OS =="
cat > "$INC/etc/os-release" <<'EOF'
PRETTY_NAME="PMX OS 0.1 (Phosphor)"
NAME="PMX OS"
VERSION_ID="0.1"
VERSION="0.1 (Phosphor)"
VERSION_CODENAME=phosphor
ID=pmxos
ID_LIKE=debian
HOME_URL="https://panmox.org/"
SUPPORT_URL="https://panmox.org/"
BUG_REPORT_URL="https://panmox.org/"
EOF
printf 'pmxos\n' > "$INC/etc/hostname"
cat > "$INC/etc/issue" <<'EOF'
  ____  __  __ __  __    ___  ____
 |  _ \|  \/  |\ \/ /   / _ \/ ___|
 | |_) | |\/| | \  /   | | | \___ \
 |  __/| |  | | /  \   | |_| |___) |
 |_|   |_|  |_|/_/\_\   \___/|____/   0.1

 Debian underneath. No telemetry. No cloud. No boss.

EOF
cat > "$INC/etc/motd" <<'EOF'

  PMX OS 0.1 (Phosphor) — the machine time forgot.
  https://panmox.org/

EOF

echo "== regenerate boot splash art with 'PMX OS' =="
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
      -annotate +0+$(( H*9/100 + ps + H/40 )) 'Debian-based   -   UEFI   -   v0.1' "$A/_bt.png"
  $IM "$A/_bt.png" -fill "$PINK" -draw "circle $(( cx + W*13/100 )),$(( H*9/100 + ps*70/100 )) $(( cx + W*13/100 + dot )),$(( H*9/100 + ps*70/100 ))" "$out"
}
gen_boot 640 480 "$A/boot_640.png"
gen_boot 800 600 "$A/boot_800.png"
rm -f "$A"/_*.png

echo "== re-embed boot art into bootloader splash.svg =="
b64=$(base64 -w0 "$A/boot_800.png")
{
  printf '%s' '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="800" height="600" viewBox="0 0 800 600">'
  printf '%s' "<image width=\"800\" height=\"600\" xlink:href=\"data:image/png;base64,$b64\"/>"
  printf '%s' '</svg>'
} > config/bootloaders/syslinux_common/splash.svg

echo "== regenerate Calamares logo -> 'PMX OS' =="
$IM -size 520x170 xc:none -gravity center -font "$FONT" -pointsize 92 \
   -fill "$INK" -annotate +0+0 'PMX OS' \
   -fill "$PINK" -draw "circle 430,118 438,118" \
   "$INC/usr/local/share/panmox/calamares-logo.png"

echo "== update Calamares hook product strings -> PMX OS =="
# patch the existing branding hook's sed targets (product/launcher) to PMX OS
sed -i 's/"PanmoxOS"/"PMX OS"/g; s/Install PanmoxOS/Install PMX OS/g; s/PanmoxOS to your disk/PMX OS to your disk/g; s/PanmoxOS 0.1/PMX OS 0.1/g' config/hooks/normal/0970-panmox-calamares.hook.chroot

echo "RENAME STAGED"
