#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"
INC=config/includes.chroot
LNF="$INC/usr/share/plasma/look-and-feel/org.panmox.desktop"

echo "== layout v2: full-screen launcher + centered floating dock + desktop monitor =="
cat > "$LNF/contents/layouts/org.kde.plasma.desktop-layout.js" <<'EOF'
// PanmoxOS desktop layout v2
var all = desktops();
for (var i = 0; i < all.length; i++) {
    var d = all[i];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file:///usr/share/wallpapers/PanmoxOS/contents/images/1920x1080.png");
}

// desktop widget: system load viewer (best effort)
try {
    var dt = all[0];
    dt.addWidget("org.kde.plasma.systemloadviewer", 80, 80, 280, 160);
} catch (e) {}

// ---- top bar ----
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

// ---- bottom dock: floating, icons centered with expanding spacers ----
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.2);
try { dock.currentConfigGroup = ["General"]; dock.writeConfig("floating", 1); } catch (e) {}

var sL = dock.addWidget("org.kde.plasma.panelspacer");
try { sL.currentConfigGroup = ["General"]; sL.writeConfig("expanding", true); } catch (e) {}

var tasks = dock.addWidget("org.kde.plasma.icontasks");
try {
    tasks.currentConfigGroup = ["General"];
    tasks.writeConfig("launchers", [
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

echo "== color scheme v2: cyan-accent titlebars =="
cat > "$INC/usr/share/color-schemes/PanmoxOS.colors" <<'EOF'
[General]
Name=PanmoxOS
ColorScheme=PanmoxOS
accentActiveTitlebar=true

[Colors:Window]
BackgroundNormal=14,20,36
BackgroundAlternate=18,26,46
ForegroundNormal=234,247,255
ForegroundInactive=130,150,180
DecorationFocus=63,224,255
DecorationHover=63,224,255

[Colors:View]
BackgroundNormal=10,15,28
BackgroundAlternate=16,23,40
ForegroundNormal=234,247,255
ForegroundInactive=130,150,180
DecorationFocus=63,224,255
DecorationHover=63,224,255

[Colors:Button]
BackgroundNormal=22,31,52
BackgroundAlternate=28,38,62
ForegroundNormal=234,247,255
DecorationFocus=63,224,255
DecorationHover=63,224,255

[Colors:Selection]
BackgroundNormal=63,224,255
BackgroundAlternate=40,180,220
ForegroundNormal=6,10,20
ForegroundInactive=6,10,20
DecorationFocus=63,224,255
DecorationHover=63,224,255

[Colors:Tooltip]
BackgroundNormal=10,15,28
ForegroundNormal=234,247,255

[Colors:Complementary]
BackgroundNormal=10,15,28
ForegroundNormal=234,247,255
DecorationFocus=255,45,126
DecorationHover=255,45,126

[WM]
activeBackground=16,52,70
activeForeground=235,248,255
activeBlend=63,224,255
inactiveBackground=12,17,30
inactiveForeground=125,145,175
inactiveBlend=12,17,30
EOF

echo "== files updated =="
ls -l "$LNF/contents/layouts/org.kde.plasma.desktop-layout.js" "$INC/usr/share/color-schemes/PanmoxOS.colors"
echo "POLISH APPLY DONE"
