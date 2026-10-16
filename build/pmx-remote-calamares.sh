#!/bin/sh
# launch calamares in the live X session, as root (calamares needs root)
XA=/home/panmox/.Xauthority
[ -f "$XA" ] || XA=$(ls /run/sddm/xauth_* 2>/dev/null | head -1)
echo "XAUTHORITY=$XA"
DISPLAY=:0 XAUTHORITY="$XA" setsid calamares -d >/tmp/cal.log 2>&1 &
sleep 9
echo "calamares pid: $(pgrep -x calamares || echo none)"
echo "--- log head ---"
head -25 /tmp/cal.log 2>/dev/null
