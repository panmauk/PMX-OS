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
for i in $(seq 1 55); do SS "echo ok" >/dev/null 2>&1 && { echo "up ~$((i*4))s"; break; }; sleep 4; done
echo "waiting for plasma..."
for i in $(seq 1 30); do SS "pgrep -u panmox plasmashell >/dev/null && echo up" 2>/dev/null | grep -q up && { echo "plasma up"; break; }; sleep 3; done
sleep 4

echo "== rename check =="
SS "grep PRETTY_NAME /etc/os-release; echo -n 'hostname: '; hostname"

echo "== open PMX Hub =="
SS "su - panmox -c 'DISPLAY=:0 XAUTHORITY=/home/panmox/.Xauthority setsid pmx-hub >/tmp/hub.log 2>&1 &'"
sleep 8
shoot pmx-hub.png
SS "echo -n 'hub pid: '; pgrep -x pmx-hub || pgrep -f pmx-hub | head -1; echo '--- hub.log ---'; tail -6 /tmp/hub.log 2>/dev/null"

echo "== toggle Phosphor mode =="
SS "pkill -f pmx-hub 2>/dev/null; su - panmox -c 'export DISPLAY=:0 XAUTHORITY=/home/panmox/.Xauthority XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus; pmx-phosphor'"
sleep 6
shoot pmx-phosphor.png
echo DONE
