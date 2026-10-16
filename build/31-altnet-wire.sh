#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"
INC=config/includes.chroot
LNF="$INC/usr/share/plasma/look-and-feel/org.panmox.desktop"
DEB=config/packages.chroot/altnet-studio_1.0.0_amd64.deb

echo "== postinst (will run in chroot at build) =="
tmp=$(mktemp -d); dpkg-deb -e "$DEB" "$tmp" 2>/dev/null || true
cat "$tmp/postinst" 2>/dev/null || echo "(no postinst)"
rm -rf "$tmp"

echo "== pin AltNet first in the dock, keep layout =="
cat > "$LNF/contents/layouts/org.kde.plasma.desktop-layout.js" <<'EOF'
// PanmoxOS desktop layout v5 (AltNet pinned)
var all = desktops();
for (var i = 0; i < all.length; i++) {
    var d = all[i];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file:///usr/share/wallpapers/PanmoxOS/contents/images/1920x1080.png");
}
var screenW = 1280;
try { screenW = screenGeometry(0).width; } catch (e) {}
var dockLen = Math.round(screenW / 3);

var top = new Panel;
top.location = "top";
top.height = Math.round(gridUnit * 1.7);
var launcher;
try { launcher = top.addWidget("org.kde.plasma.kickerdash"); }
catch (e) { launcher = top.addWidget("org.kde.plasma.kickoff"); }
try { launcher.currentConfigGroup = ["General"]; launcher.writeConfig("icon", "start-here-kde"); } catch (e) {}
top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.systemtray");
top.addWidget("org.kde.plasma.digitalclock");
top.addWidget("org.kde.plasma.showdesktop");

var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.4);
try { dock.alignment = "center"; } catch (e) {}
try { dock.minimumLength = dockLen; } catch (e) {}
try { dock.maximumLength = dockLen; } catch (e) {}
try { dock.currentConfigGroup = ["General"]; dock.writeConfig("floating", true); } catch (e) {}

var sL = dock.addWidget("org.kde.plasma.panelspacer");
try { sL.currentConfigGroup = ["General"]; sL.writeConfig("expanding", true); } catch (e) {}
var tasks = dock.addWidget("org.kde.plasma.icontasks");
try {
    tasks.currentConfigGroup = ["General"];
    tasks.writeConfig("launchers", [
        "applications:altnet-studio.desktop",
        "applications:org.kde.dolphin.desktop",
        "applications:org.kde.konsole.desktop",
        "applications:firefox-esr.desktop",
        "applications:org.kde.discover.desktop",
        "applications:systemsettings.desktop"
    ]);
} catch (e) {}
var sR = dock.addWidget("org.kde.plasma.panelspacer");
try { sR.currentConfigGroup = ["General"]; sR.writeConfig("expanding", true); } catch (e) {}
EOF

echo "ALTNET WIRE DONE"
