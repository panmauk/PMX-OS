#!/usr/bin/env bash
set -uo pipefail
KEY=/root/pmx_vm
O="-i $KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=3"
SS(){ ssh -n $O -p 2222 root@127.0.0.1 "$1"; }
echo "waiting for sshd..."
for i in $(seq 1 55); do SS "echo ok" >/dev/null 2>&1 && { echo "up ~$((i*4))s"; break; }; sleep 4; done

echo "===== settings.conf (module sequence) ====="
SS "sed -n '1,200p' /etc/calamares/settings.conf | grep -vE '^\s*#' | grep -vE '^\s*$'"
echo "===== welcome*.conf ====="
SS "for f in /etc/calamares/modules/welcome*.conf; do echo \"## \$f\"; cat \"\$f\"; done 2>/dev/null"
echo "===== partition module conf ====="
SS "for f in /etc/calamares/modules/partition*.conf; do echo \"## \$f\"; cat \"\$f\"; done 2>/dev/null"
echo "===== branding.desc (slideshow/images) ====="
SS "grep -iE 'slideshow|productName|welcomeStyle|wallpaper|*style*|background' /etc/calamares/branding/panmox/branding.desc 2>/dev/null; echo '--- branding dir ---'; ls /etc/calamares/branding/panmox/"
echo "===== where do 'Debian' strings live? ====="
SS "grep -rilE 'debian' /etc/calamares/ 2>/dev/null | head"
echo "===== partition tools present? ====="
SS "for t in parted sgdisk sfdisk mkswap mkfs.ext4 mkfs.fat partprobe udevadm; do printf '%-12s ' \$t; command -v \$t || echo MISSING; done"
echo "INSPECT DONE"
