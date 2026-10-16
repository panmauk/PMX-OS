#!/usr/bin/env bash
set -uo pipefail
python3 /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/qmp-drive.py <<'ACT'
# dismiss the breeze greeter clock to reveal the user avatar + password field
key esc
sleep 1
click 640 300
sleep 1
key ret
sleep 2
shot /root/shots/inst-login-avatar.png
ACT
cp -f /root/shots/inst-login-avatar.png /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/
echo SDDM-REVEAL DONE
