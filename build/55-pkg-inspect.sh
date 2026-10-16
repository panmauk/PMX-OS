#!/usr/bin/env bash
set -uo pipefail
KEY=/root/pmx_vm
O="-i $KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=3"
SS(){ ssh -n $O -p 2222 root@127.0.0.1 "$1"; }
echo "===== packages.conf ====="
SS "cat /etc/calamares/modules/packages.conf 2>/dev/null"
echo "===== which of the remove-list packages are actually installed? ====="
SS "for p in live-boot live-boot-doc live-config live-config-doc live-config-systemd live-tools live-task-localisation live-task-recommended calamares-settings-debian; do printf '%-26s ' \$p; dpkg -l \$p 2>/dev/null | grep -q '^ii' && echo INSTALLED || echo 'not installed'; done"
echo "===== exact apt error from calamares log ====="
SS "ls -t /root/.cache/calamares/session.log /var/log/calamares/* 2>/dev/null | head -1 | xargs grep -niE 'unable to locate|E:|not installed|returned error|remove' 2>/dev/null | tail -25"
echo INSPECT DONE
