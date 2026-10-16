#!/usr/bin/env bash
# usage: invoked with REMOTE=<local script path> SHOT=<name>
set -uo pipefail
KEY=/root/pmx_vm
O="-i $KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes"
REMOTE="${REMOTE:-/mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/pmx-remote-fix2.sh}"
SHOT="${SHOT:-pmx-live3.png}"
WAIT="${WAIT:-7}"

sed 's/\r$//' "$REMOTE" > /tmp/r.sh
scp $O -P 2222 /tmp/r.sh root@127.0.0.1:/tmp/r.sh
ssh -n $O -p 2222 root@127.0.0.1 "sh /tmp/r.sh"

sleep "$WAIT"
python3 - "$SHOT" <<'PY'
import socket,json,sys
out="/tmp/"+sys.argv[1]
s=socket.socket(socket.AF_UNIX); s.connect("/tmp/pmx-ssh-qmp.sock"); f=s.makefile('rw'); f.readline()
def cmd(c,a=None):
    o={"execute":c}
    if a:o["arguments"]=a
    f.write(json.dumps(o)+"\n");f.flush()
    while True:
        m=json.loads(f.readline())
        if "return" in m or "error" in m: return m
cmd("qmp_capabilities")
print(cmd("screendump",{"filename":out,"format":"png"}))
PY
cp -f "/tmp/$SHOT" /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/
echo "shot: $SHOT"
