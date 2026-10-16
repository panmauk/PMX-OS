#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"
INC=config/includes.chroot

echo "== polkit rule: passwordless for live user 'panmox' =="
mkdir -p "$INC/etc/polkit-1/rules.d"
cat > "$INC/etc/polkit-1/rules.d/49-panmox-nopasswd.rules" <<'EOF'
// PanmoxOS live: the live user 'panmox' is never prompted for a password.
// Scoped to 'panmox' only -> an installed system (different username) is unaffected.
polkit.addRule(function(action, subject) {
    if (subject.user == "panmox") {
        return polkit.Result.YES;
    }
});
EOF

echo "== passwordless sudo for panmox too =="
mkdir -p "$INC/etc/sudoers.d"
printf 'panmox ALL=(ALL) NOPASSWD: ALL\n' > "$INC/etc/sudoers.d/panmox-nopasswd"

echo "== hook: fix perms/ownership =="
cat > config/hooks/normal/0991-panmox-auth.hook.chroot <<'EOF'
#!/bin/sh
chmod 0440 /etc/sudoers.d/panmox-nopasswd 2>/dev/null || true
chown root:root /etc/sudoers.d/panmox-nopasswd 2>/dev/null || true
chmod 0644 /etc/polkit-1/rules.d/49-panmox-nopasswd.rules 2>/dev/null || true
chown root:root /etc/polkit-1/rules.d/49-panmox-nopasswd.rules 2>/dev/null || true
exit 0
EOF
chmod +x config/hooks/normal/0991-panmox-auth.hook.chroot
echo "POLKIT BAKE DONE"
