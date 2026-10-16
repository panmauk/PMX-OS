#!/usr/bin/env bash
set -uo pipefail
KEY=/root/pmx_vm
O="-i $KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=3"
echo "waiting for sshd..."
for i in $(seq 1 45); do
  if ssh -n $O -p 2222 root@127.0.0.1 "echo ok" >/dev/null 2>&1; then echo "up after ~$((i*4))s"; break; fi
  sleep 4
done
echo "waiting for plasma autologin to settle..."
sleep 25
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
print(cmd("screendump",{"filename":"/tmp/pmx-fresh.png","format":"png"}))
PY
cp -f /tmp/pmx-fresh.png /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/
echo DONE
