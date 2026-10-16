#!/usr/bin/env bash
# Capture installed-system GRUB (early) + SDDM login avatar (later).
set -uo pipefail
sleep 2   # let qemu create the QMP socket
python3 /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/qmp-drive.py <<'ACT'
sleep 3
shot /root/shots/inst-grub-1.png
sleep 2
shot /root/shots/inst-grub-2.png
sleep 3
shot /root/shots/inst-grub-3.png
sleep 50
shot /root/shots/inst-login-1.png
sleep 18
shot /root/shots/inst-login-2.png
ACT
cp -f /root/shots/inst-grub-*.png /root/shots/inst-login-*.png /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/
echo CAPTURE-INSTALLED DONE
