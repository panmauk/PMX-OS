#!/usr/bin/env bash
# MoxTerminal as default terminal + on the dock (Konsole unpinned);
# brand the installed-system GRUB background; replace the Debian-logo user
# avatar with a PMX one. Idempotent. Run as root in WSL.
set -uo pipefail
B="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
INC=$B/config/includes.chroot
IM=magick; command -v magick >/dev/null 2>&1 || IM=convert
FONT=/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf
INK='#EAF7FF'; CYAN='#7FE9FF'; PINK='#FF2D7E'; BASE_TOP='#06090F'; BASE_BOT='#0A1024'; GLOW='#0FA9CE'

echo "== dock: swap Konsole -> MoxTerminal =="
LAY="$INC/usr/share/plasma/look-and-feel/org.panmox.desktop/contents/layouts/org.kde.plasma.desktop-layout.js"
sed -i 's#applications:org.kde.konsole.desktop#applications:org.panmox.MoxTerminal.desktop#' "$LAY"
sed -i 's#layout v5 (AltNet pinned)#layout v6 (MoxTerminal default terminal)#' "$LAY"

echo "== default terminal in skel kdeglobals =="
KG="$INC/etc/skel/.config/kdeglobals"
sed -i '/^TerminalApplication=/d; /^TerminalService=/d' "$KG"
if grep -q '^\[General\]' "$KG"; then
  sed -i '/^\[General\]/a TerminalApplication=moxterminal\nTerminalService=org.panmox.MoxTerminal.desktop' "$KG"
else
  printf '\n[General]\nTerminalApplication=moxterminal\nTerminalService=org.panmox.MoxTerminal.desktop\n' >> "$KG"
fi

echo "== hook: register x-terminal-emulator alternative =="
cat > "$B/config/hooks/normal/0985-moxterminal.hook.chroot" <<'EOF'
#!/bin/sh
# Make MoxTerminal the system default terminal (x-terminal-emulator).
if [ -x /usr/bin/moxterminal ]; then
  update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/moxterminal 60 || true
  update-alternatives --set x-terminal-emulator /usr/bin/moxterminal || true
fi
update-desktop-database -q /usr/share/applications 2>/dev/null || true
exit 0
EOF

echo "== installed-system GRUB background (theme-independent drop-in) =="
mkdir -p "$INC/usr/share/pmx" "$INC/etc/default/grub.d"
W=1920; H=1080; cx=$((W/2)); gy=$((H*32/100))
$IM -size ${W}x${H} gradient:${BASE_TOP}-${BASE_BOT} /tmp/g_bb.png
$IM -size ${W}x${H} xc:black -fill "$GLOW" -draw "circle ${cx},${gy} ${cx},$((gy - H*20/100))" -blur 0x$((W/16)) /tmp/g_bg.png
$IM /tmp/g_bb.png /tmp/g_bg.png -compose screen -composite /tmp/g_bb.png
ps=$((H/12)); dot=$((H/55))
$IM /tmp/g_bb.png -gravity north -font "$FONT" -pointsize ${ps} -fill "$INK" \
    -annotate +0+$((H*16/100)) 'PMX OS' \
    -gravity north -pointsize $((H/34)) -fill "$CYAN" \
    -annotate +0+$((H*16/100 + ps + H/40)) 'UEFI   -   v1' /tmp/g_t.png
$IM /tmp/g_t.png -fill "$PINK" \
    -draw "circle $((cx + W*12/100)),$((H*16/100 + ps*70/100)) $((cx + W*12/100 + dot)),$((H*16/100 + ps*70/100))" \
    "$INC/usr/share/pmx/grub-bg.png"
rm -f /tmp/g_*.png
printf '# PMX OS — brand the installed-system GRUB background (overrides desktop-base)\nGRUB_BACKGROUND="/usr/share/pmx/grub-bg.png"\n' \
  > "$INC/etc/default/grub.d/pmx-grub.cfg"

echo "== user avatar: replace Debian /etc/skel/.face with a PMX avatar =="
mkdir -p "$INC/etc/skel"
AV="$INC/etc/skel/.face"
A=256; acx=$((A/2)); agy=$((A*42/100))
$IM -size ${A}x${A} gradient:${BASE_TOP}-${BASE_BOT} /tmp/a_bb.png
$IM -size ${A}x${A} xc:black -fill "$GLOW" -draw "circle ${acx},${agy} ${acx},$((agy - A*30/100))" -blur 0x$((A/8)) /tmp/a_bg.png
$IM /tmp/a_bb.png /tmp/a_bg.png -compose screen -composite /tmp/a_bb.png
$IM /tmp/a_bb.png -gravity center -font "$FONT" -pointsize $((A*46/100)) -fill "$INK" -annotate +0-6 'P' \
    -fill "$PINK" -draw "circle $((acx + A*21/100)),$((agy + A*7/100)) $((acx + A*21/100 + A/18)),$((agy + A*7/100))" \
    -strip "$AV"
rm -f /tmp/a_*.png
ln -sf .face "$INC/etc/skel/.face.icon"

echo "== verify =="
grep -n 'MoxTerminal\|konsole' "$LAY" | head
grep -nE 'TerminalApplication|TerminalService' "$KG"
ls -l "$INC/usr/share/pmx/grub-bg.png" "$INC/etc/skel/.face" "$INC/etc/skel/.face.icon" "$INC/etc/default/grub.d/pmx-grub.cfg"
echo "INTEGRATIONS DONE"
