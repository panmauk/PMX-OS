#!/usr/bin/env bash
set -uo pipefail
python3 /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/qmp-drive.py <<'ACT'
# Summary -> Install (button at ~1007,720; window shifted up)
click 1007 720
sleep 10
shot /root/shots/inst-09-installing.png
ACT
cp -f /root/shots/inst-09-installing.png /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/
echo CLICK-INSTALL DONE
