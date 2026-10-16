#!/usr/bin/env bash
# Wait for the installer VM desktop, launch Calamares, screenshot the Welcome page.
set -uo pipefail
KEY=/root/pmx_vm
O="-i $KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=3"
SS(){ ssh -n $O -p 2222 root@127.0.0.1 "$1"; }
echo "waiting for sshd..."
for i in $(seq 1 60); do SS "echo ok" >/dev/null 2>&1 && { echo "up ~$((i*4))s"; break; }; sleep 4; done
echo "waiting for plasma..."
for i in $(seq 1 30); do SS "pgrep -u panmox plasmashell >/dev/null && echo up" 2>/dev/null | grep -q up && { echo "plasma up"; break; }; sleep 3; done
sleep 6
echo "== disks seen by guest =="
SS "lsblk -dn -o NAME,SIZE,TYPE 2>/dev/null | grep disk"
echo "== launch Calamares =="
SS "pkill -x calamares 2>/dev/null; loginctl unlock-session 1 2>/dev/null; su - panmox -c 'env DISPLAY=:0 XAUTHORITY=/home/panmox/.Xauthority xhost +si:localuser:root' 2>/dev/null; DISPLAY=:0 XAUTHORITY=/home/panmox/.Xauthority setsid calamares >/tmp/cal.log 2>&1 &"
sleep 13
mkdir -p /root/shots
python3 /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/qmp-drive.py <<'ACT'
shot /root/shots/inst-01-welcome.png
ACT
cp -f /root/shots/inst-01-welcome.png /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/
echo "== cal.log tail =="; SS "tail -3 /tmp/cal.log 2>/dev/null"
echo CAL-START DONE
