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

echo "waiting for sshd..."
for i in $(seq 1 50); do SS "echo ok" >/dev/null 2>&1 && { echo "up ~$((i*4))s"; break; }; sleep 4; done

echo "== fastfetch present? =="
SS "fastfetch --version 2>&1 | head -1; ls -l /usr/share/panmox/panmox-logo.txt; grep -c fastfetch /home/panmox/.bashrc"

echo "== open Konsole (auto-runs fastfetch via .bashrc) =="
SS "su - panmox -c 'DISPLAY=:0 XAUTHORITY=/home/panmox/.Xauthority setsid konsole -p TerminalColumns=110 -p TerminalRows=34 >/dev/null 2>&1 &'"
sleep 8
shoot pmx-fastfetch.png
echo "fastfetch shot done"

echo "== calamares launches clean (no FATAL)? =="
SS "DISPLAY=:0 XAUTHORITY=/home/panmox/.Xauthority setsid calamares >/tmp/cal.log 2>&1 & sleep 9; echo pid=\$(pgrep -x calamares || echo none); grep -i 'FATAL\|ERROR' /tmp/cal.log | head -3 || echo 'no fatal'"
sleep 3
shoot pmx-cal-fresh.png
echo DONE
