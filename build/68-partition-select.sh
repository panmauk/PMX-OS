#!/usr/bin/env bash
set -uo pipefail
python3 /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/qmp-drive.py <<'ACT'
# select "Erase disk" radio
click 334 224
sleep 3
shot /root/shots/inst-05-erase.png
ACT
cp -f /root/shots/inst-05-erase.png /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/
echo PART-SELECT DONE
