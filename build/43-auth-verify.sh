#!/usr/bin/env bash
set -uo pipefail
KEY=/root/pmx_vm
O="-i $KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=3"
echo "waiting for sshd..."
for i in $(seq 1 55); do
  if ssh -n $O -p 2222 root@127.0.0.1 "echo ok" >/dev/null 2>&1; then echo "up ~$((i*4))s"; break; fi
  sleep 4
done
echo "== auth files present =="
ssh -n $O -p 2222 root@127.0.0.1 "ls -l /etc/polkit-1/rules.d/49-panmox-nopasswd.rules /etc/sudoers.d/panmox-nopasswd"
echo "== pkexec as panmox (expect 'uid=0(root)', NO password prompt) =="
ssh -n $O -p 2222 root@127.0.0.1 "su - panmox -c 'pkexec id' 2>&1 | head -3"
echo "== sudo -n as panmox (expect uid=0) =="
ssh -n $O -p 2222 root@127.0.0.1 "su - panmox -c 'sudo -n id' 2>&1 | head -2"
echo DONE
