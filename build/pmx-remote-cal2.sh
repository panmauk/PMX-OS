#!/bin/sh
D=/etc/calamares/branding/panmox/branding.desc
# componentName must equal the directory name (panmox)
if grep -q '^componentName:' "$D"; then
  sed -i 's/^componentName:.*/componentName:  panmox/' "$D"
else
  sed -i '1i componentName:  panmox' "$D"
fi
echo "componentName now: $(grep '^componentName:' "$D")"
pkill -x calamares 2>/dev/null; sleep 1
DISPLAY=:0 XAUTHORITY=/home/panmox/.Xauthority setsid calamares >/tmp/cal.log 2>&1 &
sleep 9
echo "calamares pid: $(pgrep -x calamares || echo none)"
tail -6 /tmp/cal.log
