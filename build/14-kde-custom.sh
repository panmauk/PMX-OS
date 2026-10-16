#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"
INC=config/includes.chroot
LNF="$INC/usr/share/plasma/look-and-feel/org.panmox.desktop"

echo "== extra desktop packages (icons, widgets, effects) =="
cat > config/package-lists/desktop-extra.list.chroot <<'EOF'
papirus-icon-theme
plasma-widgets-addons
kwin-addons
EOF

echo "== PanmoxOS Look-and-Feel package =="
mkdir -p "$LNF/contents/layouts"
cat > "$LNF/metadata.json" <<'EOF'
{
    "KPackageStructure": "Plasma/LookAndFeel",
    "KPlugin": {
        "Authors": [{ "Email": "hi@panmox.org", "Name": "PANMOX" }],
        "Category": "",
        "Description": "PanmoxOS custom desktop — top bar + floating dock, cyan on dark.",
        "Id": "org.panmox.desktop",
        "License": "GPLv3",
        "Name": "PanmoxOS",
        "Version": "0.1"
    }
}
EOF

# appearance defaults applied with this look-and-feel
cat > "$LNF/contents/defaults" <<'EOF'
[kdeglobals][KDE]
LookAndFeelPackage=org.panmox.desktop
widgetStyle=Breeze

[kdeglobals][General]
ColorScheme=PanmoxOS

[kdeglobals][Icons]
Theme=Papirus-Dark

[plasmarc][Theme]
name=breeze-dark

[kwinrc][org.kde.kdecoration2]
library=org.kde.breeze
theme=Breeze

[ksplashrc][KSplash]
Engine=KSplashQML
Theme=org.kde.breeze.desktop
EOF

# the layout: top bar + floating bottom icon-dock
cat > "$LNF/contents/layouts/org.kde.plasma.desktop-layout.js" <<'EOF'
// PanmoxOS desktop layout
var all = desktops();
for (var i = 0; i < all.length; i++) {
    var d = all[i];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file:///usr/share/wallpapers/PanmoxOS/contents/images/1920x1080.png");
}

// ---- top bar ----
var top = new Panel;
top.location = "top";
top.height = Math.round(gridUnit * 1.7);
var kick = top.addWidget("org.kde.plasma.kickoff");
kick.currentConfigGroup = ["General"];
kick.writeConfig("icon", "start-here-kde");
top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.systemtray");
top.addWidget("org.kde.plasma.digitalclock");
top.addWidget("org.kde.plasma.showdesktop");

// ---- floating bottom dock (icons only) ----
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.0);
try { dock.floating = true; } catch (e) {}
try { dock.alignment = "center"; } catch (e) {}
try { dock.lengthMode = "fit"; } catch (e) {}
var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:org.kde.dolphin.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:firefox-esr.desktop",
    "applications:org.kde.discover.desktop",
    "applications:systemsettings.desktop"
]);
EOF

echo "== point /etc/skel at our look-and-feel + Papirus icons =="
SK="$INC/etc/skel/.config"
mkdir -p "$SK"
cat > "$SK/kdeglobals" <<'EOF'
[General]
ColorScheme=PanmoxOS
Name=PanmoxOS
AccentColor=63,224,255
widgetStyle=Breeze

[KDE]
widgetStyle=Breeze
LookAndFeelPackage=org.panmox.desktop

[Icons]
Theme=Papirus-Dark
EOF

cat > "$SK/kwinrc" <<'EOF'
[Plugins]
blurEnabled=true
contrastEnabled=true

[org.kde.kdecoration2]
library=org.kde.breeze
theme=Breeze
EOF

echo "== first-login applier: enforce look-and-feel + colors + wallpaper =="
cat > "$INC/usr/local/bin/panmox-apply-theme.sh" <<'EOF'
#!/bin/sh
FLAG="$HOME/.config/panmox/.themed"
[ -f "$FLAG" ] && exit 0
plasma-apply-lookandfeel -a org.panmox.desktop 2>/dev/null
sleep 1
plasma-apply-colorscheme PanmoxOS 2>/dev/null
plasma-apply-wallpaperimage /usr/share/wallpapers/PanmoxOS/contents/images/1920x1080.png 2>/dev/null
mkdir -p "$HOME/.config/panmox" && touch "$FLAG"
exit 0
EOF
chmod +x "$INC/usr/local/bin/panmox-apply-theme.sh"

echo "== files =="
find "$LNF" "$SK/kdeglobals" "$SK/kwinrc" config/package-lists/desktop-extra.list.chroot -type f | sort
echo "KDE CUSTOM APPLY DONE"
