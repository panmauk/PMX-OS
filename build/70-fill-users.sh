#!/usr/bin/env bash
set -uo pipefail
python3 /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/qmp-drive.py <<'ACT'
# name (login + hostname auto-fill from this)
click 426 204
sleep 1
type panmox
sleep 1
# password
click 426 384
sleep 1
type panmox
sleep 1
# repeat password
click 632 384
sleep 1
type panmox
sleep 1
shot /root/shots/inst-07-users-filled.png
ACT
cp -f /root/shots/inst-07-users-filled.png /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/
echo FILL-USERS DONE
