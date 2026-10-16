#!/usr/bin/env bash
# Wait then snapshot install progress. Re-runnable.
set -uo pipefail
KEY=/root/pmx_vm
O="-i $KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=3"
SS(){ ssh -n $O -p 2222 root@127.0.0.1 "$1"; }
sleep "${1:-110}"
echo "--- cal.log tail ---"; SS "tail -2 /tmp/cal.log 2>/dev/null"
python3 /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/qmp-drive.py <<'ACT'
shot /root/shots/inst-progress.png
ACT
cp -f /root/shots/inst-progress.png /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/
echo SHOT-NOW DONE
