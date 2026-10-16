#!/usr/bin/env bash
set -uo pipefail
KEY=/root/pmx_vm
SSH="ssh -n -i $KEY -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=3 root@127.0.0.1"

echo "== waiting for sshd =="
for i in $(seq 1 45); do
  if $SSH "echo ok" >/dev/null 2>&1; then echo "connected after ~$((i*4))s"; break; fi
  sleep 4
done

echo "== theme dir =="
$SSH "ls /usr/share/plasma/desktoptheme/PanmoxOS/widgets/panel-background.svg* 2>&1; echo ---; sed -n '1,12p' /usr/share/plasma/desktoptheme/PanmoxOS/metadata.json 2>/dev/null"

echo "== our blue svg present + readable =="
$SSH "head -c 200 /usr/share/plasma/desktoptheme/PanmoxOS/widgets/panel-background.svg 2>&1; echo"

echo "== who is logged in, what theme is the session using =="
$SSH "loginctl 2>/dev/null | head; echo ---plasmarc---; cat /home/panmox/.config/plasmarc 2>/dev/null; echo ---kdeglobals KDE---; grep -A2 '\[KDE\]' /home/panmox/.config/kdeglobals 2>/dev/null"

echo "== session env (for driving plasma) =="
$SSH "ps -u panmox -o pid,comm 2>/dev/null | grep -iE 'plasmashell|ksmserver|kwin' ; echo ---; ls /run/user/\$(id -u panmox)/ 2>/dev/null | grep -E 'bus|wayland' ; echo DISPLAY-from-env:; cat /proc/\$(pgrep -u panmox plasmashell | head -1)/environ 2>/dev/null | tr '\0' '\n' | grep -E '^(DISPLAY|WAYLAND_DISPLAY|XDG_RUNTIME_DIR|DBUS_SESSION_BUS_ADDRESS)='"
echo "DIAG DONE"
