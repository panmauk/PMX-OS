#!/usr/bin/env bash
set -uo pipefail
cd "${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
echo "REBUILD START $(date -u +%FT%TZ)"
# keep caches (downloaded debs + bootstrap), rebuild chroot+binary with new branding
lb clean 2>&1 | tail -n 3
lb build 2>&1 | tee build.log
code=${PIPESTATUS[0]}
echo "REBUILD END $(date -u +%FT%TZ) exit=$code"
ls -lh "${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"/*.iso 2>/dev/null || echo "no ISO produced"
exit "$code"
