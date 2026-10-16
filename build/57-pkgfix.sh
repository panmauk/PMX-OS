#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"
# drop the not-installed live-task packages from Calamares' remove list
cat > config/hooks/normal/0972-panmox-calamares-packages.hook.chroot <<'EOF'
#!/bin/sh
P=/etc/calamares/modules/packages.conf
[ -f "$P" ] && sed -i "/live-task-localisation/d; /live-task-recommended/d" "$P"
exit 0
EOF
chmod +x config/hooks/normal/0972-panmox-calamares-packages.hook.chroot
echo "PKGFIX HOOK STAGED"
