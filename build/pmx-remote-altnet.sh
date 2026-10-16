#!/bin/sh
echo "=== wrapper /usr/bin/altnet-studio ==="
cat /usr/bin/altnet-studio
echo "=== launching AltNet GUI (as root, live X) ==="
pkill -f AltNetStudio 2>/dev/null; pkill -x altnet 2>/dev/null; sleep 1
DISPLAY=:0 XAUTHORITY=/home/panmox/.Xauthority setsid /opt/altnet-studio/AltNetStudio >/tmp/altnet.log 2>&1 &
sleep 12
echo "=== pids ==="; pgrep -af 'AltNetStudio|/opt/altnet-studio/altnet' | head
echo "=== log tail ==="; tail -25 /tmp/altnet.log 2>/dev/null
echo "=== listening on :80? ==="; ss -ltnp 2>/dev/null | grep ':80 ' || echo "(nothing on :80)"
