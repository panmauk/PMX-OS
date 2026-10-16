#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"
INC=config/includes.chroot
IMG="${PMXOS_AVATAR:?Set PMXOS_AVATAR to the local avatar image path}"
IM=magick; command -v magick >/dev/null 2>&1 || IM=convert

echo "== download fastfetch .deb =="
mkdir -p config/packages.chroot
curl -fsSL -o config/packages.chroot/fastfetch.deb \
  "https://github.com/fastfetch-cli/fastfetch/releases/download/2.64.2/fastfetch-linux-amd64.deb"
echo "-- deps (must be bookworm-compatible: libc6 <= 2.36) --"
dpkg-deb -I config/packages.chroot/fastfetch.deb | grep -iE 'Package:|Version:|Depends:' || true

echo "== crop cube + render to ANSI with chafa =="
W=$($IM identify -format '%w' "$IMG"); H=$($IM identify -format '%h' "$IMG")
cw=$(( W*64/100 )); ch=$(( H*66/100 )); x=$(( (W-cw)/2 )); y=$(( H*1/100 ))
$IM "$IMG" -crop ${cw}x${ch}+${x}+${y} +repage /tmp/pmx-cube.png
mkdir -p "$INC/usr/share/panmox"
chafa -f symbols -c full -s 40x20 /tmp/pmx-cube.png > "$INC/usr/share/panmox/panmox-logo.txt"
echo "logo bytes: $(wc -c < "$INC/usr/share/panmox/panmox-logo.txt")"

echo "== fastfetch config (PanmoxOS, cube logo) =="
mkdir -p "$INC/etc/skel/.config/fastfetch"
cat > "$INC/etc/skel/.config/fastfetch/config.jsonc" <<'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "type": "file-raw",
    "source": "/usr/share/panmox/panmox-logo.txt",
    "padding": { "top": 1, "left": 2, "right": 3 }
  },
  "display": { "separator": "  " },
  "modules": [
    "title",
    "separator",
    { "type": "os", "key": "OS  " },
    { "type": "kernel", "key": "Kernel  " },
    { "type": "uptime", "key": "Uptime  " },
    { "type": "packages", "key": "Packages" },
    { "type": "de", "key": "Desktop " },
    { "type": "shell", "key": "Shell   " },
    { "type": "terminal", "key": "Terminal" },
    { "type": "cpu", "key": "CPU     " },
    { "type": "memory", "key": "Memory  " },
    "break",
    "colors"
  ]
}
EOF

echo "== hook: run fastfetch on interactive shells (append, don't clobber skel) =="
cat > config/hooks/normal/0980-panmox-fastfetch.hook.chroot <<'EOF'
#!/bin/sh
LINE='[ -n "$PS1" ] && command -v fastfetch >/dev/null 2>&1 && fastfetch'
for rc in /etc/skel/.bashrc /root/.bashrc; do
  [ -f "$rc" ] || touch "$rc"
  grep -q 'command -v fastfetch' "$rc" || printf '\n# PanmoxOS greeting\n%s\n' "$LINE" >> "$rc"
done
exit 0
EOF
chmod +x config/hooks/normal/0980-panmox-fastfetch.hook.chroot

echo "FASTFETCH SETUP DONE"

