#!/bin/sh
D=/etc/calamares/branding/panmox/branding.desc
echo "=== current name/version fields ==="
grep -iE 'productName|versionedName|shortVersionedName|bootloaderEntryName' "$D"
sed -i 's#^\(\s*versionedName:\).*#\1 "PMX OS 0.1 (Phosphor)"#' "$D"
sed -i 's#^\(\s*shortVersionedName:\).*#\1 "PMX OS 0.1"#' "$D"
echo "=== after ==="
grep -iE 'versionedName' "$D"
pkill -x calamares 2>/dev/null; sleep 1
DISPLAY=:0 XAUTHORITY=/home/panmox/.Xauthority setsid calamares >/tmp/cal.log 2>&1 &
sleep 9
loginctl unlock-session 1 2>/dev/null; pkill -f kscreenlocker 2>/dev/null; sleep 1
pgrep -x calamares >/dev/null && echo running || echo FAILED
