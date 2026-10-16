#!/usr/bin/env bash
# Verify MoxTerminal in the booted VM: on the dock + launches + is the default.
set -uo pipefail
KEY=/root/pmx_vm
SSHO="-n -i $KEY -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5"
R(){ ssh $SSHO root@127.0.0.1 "$1"; }
PENV='env DISPLAY=:0 XAUTHORITY=/home/panmox/.Xauthority XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus'
PL(){ R "su - panmox -c '$PENV setsid $1 >/dev/null 2>&1 </dev/null &'"; }
KILL(){ R "pkill -u panmox -f '$1' 2>/dev/null; true"; }

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

echo "== wait for SSH + plasmashell =="
for i in $(seq 1 24); do R "true" 2>/dev/null && break; sleep 5; done
for i in $(seq 1 30); do R "pgrep -u panmox plasmashell >/dev/null && echo up" 2>/dev/null | grep -q up && { echo "plasma up ~$((i*5))s"; break; }; sleep 5; done
sleep 8

echo "== default-terminal settings (in the running image) =="
R "echo '-- x-terminal-emulator --'; update-alternatives --query x-terminal-emulator 2>/dev/null | grep -E 'Value|moxterminal'; echo '-- kdeglobals --'; grep -E 'TerminalApplication|TerminalService' /etc/skel/.config/kdeglobals; echo '-- which moxterminal --'; ls -l /usr/bin/moxterminal"

echo "== 1) desktop: dock should show MoxTerminal, not Konsole =="
KILL pmx-hub; KILL WebKitWebProcess; sleep 3
SHOT /root/shots/10-dock-moxterminal.png

echo "== 2) launch MoxTerminal =="
PL "moxterminal"; sleep 9
R "echo '-- mox running? --'; pgrep -af moxterminal | head"
SHOT /root/shots/11-moxterminal.png

DST=/mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots
mkdir -p "$DST"; cp -f /root/shots/10-dock-moxterminal.png /root/shots/11-moxterminal.png "$DST"/ 2>/dev/null
echo "MOX SHOTS DONE"
