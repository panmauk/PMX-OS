#!/usr/bin/env bash
set -uo pipefail
python3 /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/qmp-drive.py <<'ACT'
# Partitions -> Users
click 1007 655
sleep 4
shot /root/shots/inst-06-users.png
ACT
cp -f /root/shots/inst-06-users.png /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/
echo TO-USERS DONE
