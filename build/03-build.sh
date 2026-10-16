#!/usr/bin/env bash
set -uo pipefail
cd "${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
echo "BUILD START $(date -u +%FT%TZ)"
# lb build does: bootstrap (debootstrap) -> chroot (install KDE etc) -> binary (squashfs + ISO)
lb build 2>&1 | tee build.log
code=${PIPESTATUS[0]}
echo "BUILD END $(date -u +%FT%TZ) exit=$code"
echo "== artifacts =="
ls -lh "${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"/*.iso 2>/dev/null || echo "no ISO produced"
exit "$code"
