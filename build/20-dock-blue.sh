#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"
INC=config/includes.chroot
LNF="$INC/usr/share/plasma/look-and-feel/org.panmox.desktop"

echo "== layout v3: short (~1/3) floating centered dock =="
cat > "$LNF/contents/layouts/org.kde.plasma.desktop-layout.js" <<'EOF'
// PanmoxOS desktop layout v3
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

// ---- bottom dock: ~1/3 width, centered, floating ----
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.4);
try { dock.alignment = "center"; } catch (e) {}
try { dock.minimumLength = dockLen; } catch (e) {}
try { dock.maximumLength = dockLen; } catch (e) {}
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

echo "== color scheme v3: BLUE panels/windows/titlebars, cyan accent =="
cat > "$INC/usr/share/color-schemes/PanmoxOS.colors" <<'EOF'
[General]
Name=PanmoxOS
ColorScheme=PanmoxOS
accentActiveTitlebar=true

[Colors:Window]
BackgroundNormal=18,30,66
BackgroundAlternate=24,38,80
ForegroundNormal=233,243,255
ForegroundInactive=150,170,210
ForegroundActive=63,224,255
DecorationFocus=63,224,255
DecorationHover=63,224,255

[Colors:View]
BackgroundNormal=12,20,48
BackgroundAlternate=18,28,62
ForegroundNormal=233,243,255
ForegroundInactive=150,170,210
DecorationFocus=63,224,255
DecorationHover=63,224,255

[Colors:Button]
BackgroundNormal=28,44,92
BackgroundAlternate=34,52,108
ForegroundNormal=233,243,255
DecorationFocus=63,224,255
DecorationHover=63,224,255

[Colors:Selection]
BackgroundNormal=63,200,255
BackgroundAlternate=46,170,230
ForegroundNormal=6,12,28
ForegroundInactive=6,12,28
DecorationFocus=63,224,255
DecorationHover=63,224,255

[Colors:Header]
BackgroundNormal=22,38,86
BackgroundAlternate=18,30,68
ForegroundNormal=233,243,255
ForegroundInactive=150,170,210
DecorationFocus=63,224,255
DecorationHover=63,224,255

[Colors:Tooltip]
BackgroundNormal=14,24,56
ForegroundNormal=233,243,255

[Colors:Complementary]
BackgroundNormal=12,20,48
ForegroundNormal=233,243,255
DecorationFocus=255,45,126
DecorationHover=255,45,126

[WM]
activeBackground=26,46,104
activeForeground=235,246,255
activeBlend=63,224,255
inactiveBackground=16,26,54
inactiveForeground=140,160,200
inactiveBlend=16,26,54
EOF

echo "DOCK+BLUE APPLY DONE"
