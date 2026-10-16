#!/bin/sh
echo "=== /usr/lib/os-release PRETTY ==="; grep -E 'PRETTY_NAME|^VERSION=' /usr/lib/os-release 2>/dev/null
echo "=== /etc/os-release PRETTY ==="; grep -E 'PRETTY_NAME' /etc/os-release 2>/dev/null
echo "=== overriding /usr/lib/os-release ==="
cp -f /etc/os-release /usr/lib/os-release
pkill -x calamares 2>/dev/null; sleep 1
DISPLAY=:0 XAUTHORITY=/home/panmox/.Xauthority setsid calamares >/tmp/cal.log 2>&1 &
sleep 10
pgrep -x calamares >/dev/null && echo "calamares running" || { echo FAILED; tail -5 /tmp/cal.log; }
