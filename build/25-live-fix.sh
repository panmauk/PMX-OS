#!/usr/bin/env bash
set -uo pipefail
KEY=/root/pmx_vm
O="-i $KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes"

# strip CRLF then push the remote fix script
sed 's/\r$//' /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/pmx-remote-fix.sh > /tmp/fix.sh
scp $O -P 2222 /tmp/fix.sh root@127.0.0.1:/tmp/fix.sh
ssh -n $O -p 2222 root@127.0.0.1 "sh /tmp/fix.sh"

echo "== screenshot after apply =="
sleep 5
python3 - <<'PY'
import socket,json
s=socket.socket(socket.AF_UNIX); s.connect("/tmp/pmx-ssh-qmp.sock"); f=s.makefile('rw'); f.readline()
def cmd(c,a=None):
    o={"execute":c}
    if a:o["arguments"]=a
    f.write(json.dumps(o)+"\n");f.flush()
    while True:
        m=json.loads(f.readline())
        if "return" in m or "error" in m: return m
cmd("qmp_capabilities")
print(cmd("screendump",{"filename":"/tmp/pmx-live2.png","format":"png"}))
PY
mkdir -p /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots
cp -f /tmp/pmx-live2.png /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/
echo "LIVE FIX DONE"
