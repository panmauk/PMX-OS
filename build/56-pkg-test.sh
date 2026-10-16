#!/usr/bin/env bash
set -uo pipefail
KEY=/root/pmx_vm
O="-i $KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=3"
SS(){ ssh -n $O -p 2222 root@127.0.0.1 "$1"; }
echo "=== reproduce: remove incl. the not-installed task pkgs (dry-run) ==="
SS "apt-get --purge -q -y -s remove live-task-localisation live-task-recommended >/tmp/e1 2>&1; echo exit=\$?; tail -2 /tmp/e1"
echo "=== fix: remove only the installed pkgs (dry-run) ==="
SS "apt-get --purge -q -y -s remove live-boot live-boot-doc live-config live-config-doc live-config-systemd live-tools calamares-settings-debian >/tmp/o2 2>&1; echo exit=\$?; tail -3 /tmp/o2"
echo TEST DONE
