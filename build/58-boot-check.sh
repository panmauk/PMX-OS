#!/usr/bin/env bash
set -uo pipefail
for i in $(seq 1 20); do [ -S /tmp/pmx-inst-qmp.sock ] && break; sleep 1; done
sleep 45
python3 - <<'PY'
import socket,json
s=socket.socket(socket.AF_UNIX); s.connect("/tmp/pmx-inst-qmp.sock"); f=s.makefile("rw"); f.readline()
def cmd(c,a=None):
    o={"execute":c}
    if a:o["arguments"]=a
    f.write(json.dumps(o)+"\n");f.flush()
    while True:
        m=json.loads(f.readline())
        if "return" in m or "error" in m: return m
cmd("qmp_capabilities"); print(cmd("screendump",{"filename":"/tmp/pmx-booted.png","format":"png"}))
PY
cp -f /tmp/pmx-booted.png /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/
echo DONE
