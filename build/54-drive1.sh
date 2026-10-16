#!/usr/bin/env bash
set -uo pipefail
python3 /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/qmp-drive.py <<'ACT'
# Welcome -> Next
click 1007 655
sleep 4
shot /tmp/i2.png
# Location -> Next
click 1007 655
sleep 4
shot /tmp/i3.png
# Keyboard -> Next
click 1007 655
sleep 4
shot /tmp/i4.png
ACT
cp -f /tmp/i2.png /tmp/i3.png /tmp/i4.png /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/
echo DRIVE1 DONE
