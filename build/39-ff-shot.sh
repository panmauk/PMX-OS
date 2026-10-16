#!/usr/bin/env bash
set -uo pipefail
KEY=/root/pmx_vm
O="-i $KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=3"
SS(){ ssh -n $O -p 2222 root@127.0.0.1 "$1"; }
shoot(){ python3 - "$1" <<'PY'
import socket,json,sys
s=socket.socket(socket.AF_UNIX); s.connect("/tmp/pmx-ssh-qmp.sock"); f=s.makefile('rw'); f.readline()
def cmd(c,a=None):
    o={"execute":c}
    if a:o["arguments"]=a
    f.write(json.dumps(o)+"\n");f.flush()
    while True:
        m=json.loads(f.readline())
        if "return" in m or "error" in m: return m
cmd("qmp_capabilities"); print(cmd("screendump",{"filename":"/tmp/"+sys.argv[1],"format":"png"}))
PY
cp -f "/tmp/$1" /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/; }

echo "wait for plasma..."
for i in $(seq 1 30); do
  if SS "pgrep -u panmox plasmashell >/dev/null && echo up" 2>/dev/null | grep -q up; then echo "plasma up ~$((i*3))s"; break; fi
  sleep 3
done
sleep 3
echo "close calamares, open fresh konsole..."
SS "pkill -x calamares 2>/dev/null; pkill -u panmox konsole 2>/dev/null; sleep 1; su - panmox -c 'DISPLAY=:0 XAUTHORITY=/home/panmox/.Xauthority setsid konsole -p TerminalColumns=112 -p TerminalRows=34 >/dev/null 2>&1 &'"
sleep 8
shoot pmx-ff2.png
echo DONE
