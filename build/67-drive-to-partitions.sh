#!/usr/bin/env bash
set -uo pipefail
python3 /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/qmp-drive.py <<'ACT'
# Welcome -> Location
click 1007 655
sleep 4
shot /root/shots/inst-02-location.png
# Location -> Keyboard
click 1007 655
sleep 4
shot /root/shots/inst-03-keyboard.png
# Keyboard -> Partitions
click 1007 655
sleep 4
shot /root/shots/inst-04-partitions.png
ACT
cp -f /root/shots/inst-02-location.png /root/shots/inst-03-keyboard.png /root/shots/inst-04-partitions.png /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/
echo DRIVE-TO-PART DONE
