#!/usr/bin/env bash
# Boot must already be running (build/23-vm-ssh.sh). Drives the live Plasma
# session over SSH, stages each app, and QMP-screendumps to build/shots/.
set -uo pipefail
KEY=/root/pmx_vm
SSHO="-n -i $KEY -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5"
R(){ ssh $SSHO root@127.0.0.1 "$1"; }
# env to talk to panmox's running Plasma session
PENV='env DISPLAY=:0 XAUTHORITY=/home/panmox/.Xauthority XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus'
PL(){ R "su - panmox -c '$PENV setsid $1 >/dev/null 2>&1 </dev/null &'"; }
KILL(){ R "pkill -u panmox -f '$1' 2>/dev/null; true"; }
mkdir -p /root/shots

cat > /root/qshot.py <<'PY'
import socket,json,sys
s=socket.socket(socket.AF_UNIX);s.connect("/tmp/pmx-ssh-qmp.sock");f=s.makefile('rw');f.readline()
def cmd(c,a=None):
    o={"execute":c}
    if a:o["arguments"]=a
    f.write(json.dumps(o)+"\n");f.flush()
    while True:
        m=json.loads(f.readline())
        if "return" in m or "error" in m: return m
cmd("qmp_capabilities")
sys.stderr.write(str(cmd("screendump",{"filename":sys.argv[1],"format":"png"}))+"\n")
PY
SHOT(){ python3 /root/qshot.py "$1"; sleep 1.3; echo "  shot -> $1"; }

echo "== wait for SSH =="
for i in $(seq 1 24); do R "true" 2>/dev/null && { echo "ssh up ~$((i*5))s"; break; }; sleep 5; done

echo "== wait for plasmashell (panmox) =="
for i in $(seq 1 30); do
  R "pgrep -u panmox plasmashell >/dev/null && echo up" 2>/dev/null | grep -q up && { echo "plasma up ~$((i*5))s"; break; }
  sleep 5
done
sleep 8

echo "== 01 clean desktop (close auto-opened Hub) =="
KILL pmx-hub; KILL WebKitWebProcess; sleep 3
SHOT /root/shots/01-desktop.png

echo "== 02 PMX Hub =="
PL "/usr/local/bin/pmx-hub"; sleep 9
SHOT /root/shots/02-pmx-hub.png
KILL pmx-hub; KILL WebKitWebProcess; sleep 3

echo "== 03 AltNet Studio =="
PL "/usr/bin/altnet-studio"; sleep 11
SHOT /root/shots/03-altnet.png

echo "== 04 Konsole + fastfetch cube =="
PL "konsole"; sleep 8
SHOT /root/shots/04-konsole-fastfetch.png

echo "== 05 Phosphor green retro mode =="
R "su - panmox -c '$PENV /usr/local/bin/pmx-phosphor' 2>/dev/null; true"; sleep 7
SHOT /root/shots/05-phosphor.png
R "su - panmox -c '$PENV /usr/local/bin/pmx-phosphor' 2>/dev/null; true"; sleep 4   # back to blue

DST=/mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots
mkdir -p "$DST"; cp -f /root/shots/*.png "$DST"/ 2>/dev/null
echo "== sizes =="; ls -l /root/shots/
echo SHOTS DONE
