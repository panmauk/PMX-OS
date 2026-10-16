#!/bin/sh
mkdir -p /etc/polkit-1/rules.d
cat > /etc/polkit-1/rules.d/49-panmox-nopasswd.rules <<'R'
// PanmoxOS live: the live user 'panmox' never gets an auth prompt.
// Scoped to panmox only, so an installed system (different user) is unaffected.
polkit.addRule(function(action, subject) {
    if (subject.user == "panmox") {
        return polkit.Result.YES;
    }
});
R
echo "panmox ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/panmox-nopasswd
chmod 440 /etc/sudoers.d/panmox-nopasswd
systemctl restart polkit 2>/dev/null || systemctl restart polkitd 2>/dev/null || true
sleep 2
echo "--- pkexec test (expect uid=0 root, no prompt) ---"
su - panmox -c "pkexec id" 2>&1 | head -3
echo "--- sudo -n test ---"
su - panmox -c "sudo -n id" 2>&1 | head -2
