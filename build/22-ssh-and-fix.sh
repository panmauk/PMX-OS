#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"
INC=config/includes.chroot

echo "== host SSH keypair for VM access =="
if [ ! -f /root/pmx_vm ]; then
  ssh-keygen -t ed25519 -N "" -f /root/pmx_vm -C panmox-vm >/dev/null
fi
PUB=$(cat /root/pmx_vm.pub)

echo "== install pubkey for root in the image =="
mkdir -p "$INC/root/.ssh"
echo "$PUB" > "$INC/root/.ssh/authorized_keys"

cat > config/package-lists/ssh.list.chroot <<'L'
openssh-server
L

cat > config/hooks/normal/0960-panmox-ssh.hook.chroot <<'H'
#!/bin/sh
mkdir -p /root/.ssh
chmod 700 /root/.ssh
[ -f /root/.ssh/authorized_keys ] && chmod 600 /root/.ssh/authorized_keys
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config 2>/dev/null || true
systemctl enable ssh 2>/dev/null || true
exit 0
H
chmod +x config/hooks/normal/0960-panmox-ssh.hook.chroot

echo "== rebuild plasma-theme hook with theme-id fix =="
cat > config/hooks/normal/0950-panmox-plasma-theme.hook.chroot <<'H'
#!/bin/sh
SRC=""
for c in /usr/share/plasma/desktoptheme/breeze-dark /usr/share/plasma/desktoptheme/default; do
  [ -d "$c" ] && SRC="$c" && break
done
[ -z "$SRC" ] && exit 0
DST=/usr/share/plasma/desktoptheme/PanmoxOS
rm -rf "$DST"; cp -a "$SRC" "$DST"
find "$DST" -name 'panel-background.svg*' -print | while read f; do
  d=$(dirname "$f"); rm -f "$d"/panel-background.svg*
  cp /usr/local/share/panmox/panel-background.svg "$d"/panel-background.svg
done
# force the theme to identify as PanmoxOS so selecting it actually works
if [ -f "$DST/metadata.json" ]; then
  sed -i 's/"Id"[[:space:]]*:[[:space:]]*"[^"]*"/"Id": "PanmoxOS"/' "$DST/metadata.json"
  sed -i 's/"Name"[[:space:]]*:[[:space:]]*"[^"]*"/"Name": "PanmoxOS"/' "$DST/metadata.json"
fi
if [ -f "$DST/metadata.desktop" ]; then
  sed -i 's/^Name=.*/Name=PanmoxOS/' "$DST/metadata.desktop"
  sed -i 's/^X-KDE-PluginInfo-Name=.*/X-KDE-PluginInfo-Name=PanmoxOS/' "$DST/metadata.desktop"
fi
exit 0
H
chmod +x config/hooks/normal/0950-panmox-plasma-theme.hook.chroot

echo "SSH+FIX DONE"
echo "VM private key: /root/pmx_vm"
