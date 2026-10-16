#!/usr/bin/env bash
echo "=== target disk ==="; ls -lh /tmp/pmx-target.qcow2 2>&1
echo "=== nvram vars ==="; ls -lh /tmp/pmx-inst-VARS.fd 2>&1
echo "=== installed vm log ==="; cat /tmp/pmx-installed.log 2>&1 | head -20
echo "=== qemu procs ==="; pgrep -x qemu-system-x86_64 >/dev/null 2>&1 && pgrep -afx qemu-system-x86_64 | head || echo "none running"
echo "=== disk content (is install there?) ==="; qemu-img info /tmp/pmx-target.qcow2 2>&1 | grep -E 'disk size|virtual size'
