#!/usr/bin/env bash
set -uo pipefail
export DEBIAN_FRONTEND=noninteractive

command -v magick >/dev/null 2>&1 || command -v convert >/dev/null 2>&1 || {
  echo "== installing imagemagick + fonts =="
  apt-get update -qq
  apt-get install -y --no-install-recommends imagemagick fonts-dejavu-core
}
IM=magick; command -v magick >/dev/null 2>&1 || IM=convert
echo "using: $IM"

# pick a serif font if available, else fall back to IM default
FONT=""
for c in /usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf \
         /usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf; do
  [ -f "$c" ] && FONT="$c" && break
done
FONTOPT=(); [ -n "$FONT" ] && FONTOPT=(-font "$FONT")
echo "font: ${FONT:-<im-default>}"

A="${PMXOS_ASSETS_DIR:?Set PMXOS_ASSETS_DIR}"
mkdir -p "$A"

# ---- PALETTE (from panmox.org): near-black indigo base, cyan glow, pink dot ----
BASE_TOP='#06090F'; BASE_BOT='#0A1024'; GLOW='#0FA9CE'; GLOW_CORE='#39DBFF'
CYAN='#7FE9FF'; INK='#EAF7FF'; PINK='#FF2D7E'; VIGNETTE='#0a0d18'

gen_wp() { # $1=W $2=H $3=out  (desktop wallpaper / login bg)
  local W=$1 H=$2 out=$3 cx=$(( $1/2 )) gy=$(( $2*70/100 ))
  $IM -size ${W}x${H} gradient:${BASE_TOP}-${BASE_BOT} "$A/_b.png"
  $IM -size ${W}x${H} xc:black -fill "$GLOW"      -draw "circle ${cx},${gy} ${cx},$(( gy - H*27/100 ))" -blur 0x$(( W/12 )) "$A/_g1.png"
  $IM "$A/_b.png" "$A/_g1.png" -compose screen -composite "$A/_b.png"
  $IM -size ${W}x${H} xc:black -fill "$GLOW_CORE" -draw "circle ${cx},${gy} ${cx},$(( gy - H*6/100 ))"  -blur 0x$(( W/26 )) "$A/_g2.png"
  $IM "$A/_b.png" "$A/_g2.png" -compose screen -composite "$A/_b.png"
  $IM "$A/_b.png" \( -size ${W}x${H} radial-gradient:'#ffffff'-${VIGNETTE} \) -compose multiply -composite "$A/_b.png"
  # subtle 'P A N M O X' signature, lower area
  $IM "$A/_b.png" -gravity south "${FONTOPT[@]}" -pointsize $(( H/30 )) -fill "$CYAN" \
      -annotate +0+$(( H/14 )) 'P A N M O X' "$out"
  echo "  wrote $out"
}

gen_boot() { # $1=W $2=H $3=out  (boot menu background: PanmoxOS title up top, menu below)
  local W=$1 H=$2 out=$3 cx=$(( $1/2 )) gy=$(( $2*30/100 ))
  $IM -size ${W}x${H} gradient:${BASE_TOP}-${BASE_BOT} "$A/_bb.png"
  $IM -size ${W}x${H} xc:black -fill "$GLOW" -draw "circle ${cx},${gy} ${cx},$(( gy - H*22/100 ))" -blur 0x$(( W/14 )) "$A/_bg.png"
  $IM "$A/_bb.png" "$A/_bg.png" -compose screen -composite "$A/_bb.png"
  # Title 'PanmoxOS' + pink dot
  local ps=$(( H/9 )); local dot=$(( H/40 ))
  $IM "$A/_bb.png" -gravity north "${FONTOPT[@]}" -pointsize ${ps} -fill "$INK" \
      -annotate +0+$(( H*9/100 )) 'PanmoxOS' \
      -gravity north -pointsize $(( H/26 )) -fill "$CYAN" \
      -annotate +0+$(( H*9/100 + ps + H/40 )) 'Debian-based   -   UEFI   -   v0.1' "$A/_bt.png"
  # pink dot after the title (approx position right of centered word)
  $IM "$A/_bt.png" -fill "$PINK" -draw "circle $(( cx + W*16/100 )),$(( H*9/100 + ps*70/100 )) $(( cx + W*16/100 + dot )),$(( H*9/100 + ps*70/100 ))" "$out"
  echo "  wrote $out"
}

echo "== generating assets =="
gen_wp   1920 1080 "$A/wallpaper_1920.png"
gen_boot  640  480 "$A/boot_640.png"
gen_boot 1920 1080 "$A/boot_1920.png"
rm -f "$A"/_*.png

# copy previews to Windows side so they can be viewed
DEST=/mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots
mkdir -p "$DEST"
cp -f "$A/wallpaper_1920.png" "$A/boot_640.png" "$DEST/" 2>/dev/null && echo "previews -> $DEST"
echo "== results =="
ls -l "$A"
echo "ASSETS DONE"
