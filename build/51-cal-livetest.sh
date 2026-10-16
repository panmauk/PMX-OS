#!/usr/bin/env bash
set -uo pipefail
KEY=/root/pmx_vm
O="-i $KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=3"
INC="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"/config/includes.chroot
scp $O -P 2222 "$INC/usr/local/share/panmox/cal-welcome.png" root@127.0.0.1:/tmp/cal-welcome.png
scp $O -P 2222 "$INC/etc/calamares/modules/partition.conf" root@127.0.0.1:/tmp/partition.conf
sed 's/\r$//' /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/pmx-remote-caltest.sh > /tmp/ct.sh
scp $O -P 2222 /tmp/ct.sh root@127.0.0.1:/tmp/ct.sh
ssh -n $O -p 2222 root@127.0.0.1 "sh /tmp/ct.sh"
sleep 3
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
cmd("qmp_capabilities"); print(cmd("screendump",{"filename":"/tmp/pmx-cal-fixed.png","format":"png"}))
PY
cp -f /tmp/pmx-cal-fixed.png /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/shots/
echo DONE
