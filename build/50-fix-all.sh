#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"
INC=config/includes.chroot
IM=magick; command -v magick >/dev/null 2>&1 || IM=convert
FONT=/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf

echo "== PMX calamares welcome/slide image =="
W=1280; H=720; cx=$((W/2)); gy=$((H*44/100))
$IM -size ${W}x${H} gradient:'#06090F'-'#0A1024' /tmp/cw.png
$IM -size ${W}x${H} xc:black -fill '#0FA9CE' -draw "circle ${cx},${gy} ${cx},$(( gy - H*26/100 ))" -blur 0x$((W/14)) /tmp/cwg.png
$IM /tmp/cw.png /tmp/cwg.png -compose screen -composite /tmp/cw.png
$IM /tmp/cw.png -gravity center -font "$FONT" -pointsize 120 -fill '#EAF7FF' -annotate +0-40 'PMX OS' \
   -fill '#FF2D7E' -draw "circle $((cx+250)),$((H/2-18)) $((cx+260)),$((H/2-18))" \
   -gravity center -pointsize 30 -fill '#7FE9FF' -annotate +0+70 'A peer-to-peer internet, in an operating system.' \
   "$INC/usr/local/share/panmox/cal-welcome.png"
rm -f /tmp/cw*.png
echo "  $(ls -l "$INC/usr/local/share/panmox/cal-welcome.png" | awk '{print $5}') bytes"

echo "== Calamares partition.conf -> swapfile (no swap partition) =="
mkdir -p "$INC/etc/calamares/modules"
cat > "$INC/etc/calamares/modules/partition.conf" <<'EOF'
efiSystemPartition:     "/boot/efi"
userSwapChoices:
    - none
    - small
    - file
initialSwapChoice:      file
drawNestedPartitions:   false
alwaysShowPartitionLabels: true
defaultFileSystemType:  "ext4"
availableFileSystemTypes: ["ext4","btrfs","xfs"]
enableLuksAutomatedPartitioning: false
EOF

echo "== rewrite Calamares branding hook (PMX strings, welcome style, kill Debian art) =="
cat > config/hooks/normal/0970-panmox-calamares.hook.chroot <<'EOF'
#!/bin/sh
[ -d /etc/calamares ] || exit 0
BR=/etc/calamares/branding
if [ -d "$BR/debian" ]; then rm -rf "$BR/panmox"; cp -r "$BR/debian" "$BR/panmox"; else mkdir -p "$BR/panmox"; fi
# kill Debian artwork
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

echo "== Hub HTML: remove AltNet, point at panmox.org =="
cat > "$INC/usr/share/panmox/hub/index.html" <<'HTML'
<!doctype html><html><head><meta charset="utf-8"><style>
:root{--bg:#080d1c;--bg2:#0c1430;--cyan:#3fe0ff;--ink:#eaf4ff;--mut:#8ea6c8;--pink:#ff2d7e;--card:#10193a;--line:#1d2c55}
*{box-sizing:border-box;margin:0;padding:0;font-family:'DejaVu Sans',sans-serif}
body{background:radial-gradient(60% 60% at 50% 35%,#11224a 0%,var(--bg) 70%);color:var(--ink);min-height:100vh;padding:48px 40px}
.brand{font-size:13px;letter-spacing:.5em;color:var(--cyan);text-transform:uppercase}
h1{font-size:54px;font-weight:800;margin:6px 0 2px} h1 .d{color:var(--pink)}
.sub{color:var(--mut);font-size:17px;margin-bottom:34px}
.row{display:grid;grid-template-columns:1fr 1fr;gap:18px;margin-bottom:26px}
.card{background:var(--card);border:1px solid var(--line);border-radius:16px;padding:22px 24px;cursor:pointer;transition:.15s;text-decoration:none;color:var(--ink);display:block}
.card:hover{border-color:var(--cyan);transform:translateY(-2px);box-shadow:0 8px 30px #0006}
.card h3{font-size:21px;margin-bottom:6px} .card p{color:var(--mut);font-size:14px;line-height:1.5}
.k{font-size:12px;letter-spacing:.25em;color:var(--cyan);text-transform:uppercase;margin-bottom:16px}
.apps{display:grid;grid-template-columns:repeat(3,1fr);gap:14px}
.app{background:var(--bg2);border:1px solid var(--line);border-radius:12px;padding:16px;text-align:center;text-decoration:none;color:var(--ink);font-size:14px;transition:.15s}
.app:hover{border-color:var(--cyan)} .app small{display:block;color:var(--mut);font-size:11px;margin-top:3px}
.foot{color:var(--mut);font-size:12px;margin-top:30px;text-align:center}
</style></head><body>
  <div class="brand">● PANMOX</div>
  <h1>PMX OS<span class="d">.</span></h1>
  <div class="sub">A peer-to-peer internet, in an operating system. <i>No cloud. No telemetry. No boss.</i></div>

  <div class="row">
    <a class="card" href="cmd:install"><h3>Install PMX OS →</h3><p>Put PMX OS on your disk — UEFI, full disk or alongside your current system.</p></a>
    <a class="card" href="https://panmox.org/"><h3>Explore PANMOX →</h3><p>Products, downloads and the story — everything PANMOX, at panmox.org.</p></a>
  </div>

  <div class="k">From PANMOX</div>
  <div class="apps">
    <a class="app" href="https://panmox.org/">NeuralXP™<small>panmox.org</small></a>
    <a class="app" href="https://panmox.org/">PANMOX Browser™<small>panmox.org</small></a>
    <a class="app" href="https://panmox.org/">LostEngine™<small>panmox.org</small></a>
  </div>
  <div class="foot">PMX OS 0.1 “Phosphor” · Debian underneath · panmox.org</div>
</body></html>
HTML

echo "FIX-ALL STAGED"
