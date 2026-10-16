#!/usr/bin/env bash
set -uo pipefail
KEY=/root/pmx_vm
SSHO="-n -i $KEY -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5"
R(){ ssh $SSHO root@127.0.0.1 "$1"; }
PENV='env DISPLAY=:0 XAUTHORITY=/home/panmox/.Xauthority XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus'
SHOT(){ python3 /root/qshot.py "$1"; sleep 1.3; echo "shot $1"; }

echo "== clean slate =="
R "pkill -u panmox konsole 2>/dev/null; pkill -f AltNetStudio 2>/dev/null; sleep 1; true"; sleep 2

echo "== let root draw on panmox's X, launch AltNet GUI directly as root =="
R "su - panmox -c '$PENV xhost +si:localuser:root' 2>/dev/null; true"
R "setsid env DISPLAY=:0 XAUTHORITY=/home/panmox/.Xauthority GDK_BACKEND=x11 /opt/altnet-studio/AltNetStudio >/tmp/altnet.log 2>&1 </dev/null &"
sleep 16
echo "-- procs / log --"
R "pgrep -af AltNetStudio || echo '(not running)'; echo '--- log ---'; head -25 /tmp/altnet.log 2>/dev/null"
SHOT /root/shots/03-altnet.png

echo "== clean Phosphor-green desktop shot =="
R "pkill -f AltNetStudio 2>/dev/null; sleep 1; true"; sleep 2
R "su - panmox -c '$PENV /usr/local/bin/pmx-phosphor' 2>/dev/null; true"; sleep 6
SHOT /root/shots/06-phosphor-desktop.png
R "su - panmox -c '$PENV /usr/local/bin/pmx-phosphor' 2>/dev/null; true"; sleep 3   # back to blue

cp -f /root/shots/03-altnet.png /root/shots/06-phosphor-desktop.png /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/ 2>/dev/null
echo DONE
