#!/usr/bin/env bash
set -uo pipefail
KEY=/root/pmx_vm
O="-i $KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=3"
echo "waiting for sshd..."
for i in $(seq 1 55); do
  if ssh -n $O -p 2222 root@127.0.0.1 "echo ok" >/dev/null 2>&1; then echo "up ~$((i*4))s"; break; fi
  sleep 4
done
sed 's/\r$//' /mnt/c/Users/${WINDOWS_USER:?Set WINDOWS_USER}/Documents/OS/build/pmx-remote-polkit.sh > /tmp/pk.sh
scp $O -P 2222 /tmp/pk.sh root@127.0.0.1:/tmp/pk.sh
ssh -n $O -p 2222 root@127.0.0.1 "sh /tmp/pk.sh"
echo DONE
