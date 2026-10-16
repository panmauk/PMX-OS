#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"
INC=config/includes.chroot
LNF="$INC/usr/share/plasma/look-and-feel/org.panmox.desktop"

echo "== blue panel-background SVG (9-slice; lighter blue top edge) =="
mkdir -p "$INC/usr/local/share/panmox"
cat > "$INC/usr/local/share/panmox/panel-background.svg" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="60" height="60" viewBox="0 0 60 60">
  <rect id="topleft"     x="0"  y="0"  width="6"  height="6"  fill="#274C86"/>
  <rect id="top"         x="6"  y="0"  width="48" height="6"  fill="#274C86"/>
  <rect id="topright"    x="54" y="0"  width="6"  height="6"  fill="#274C86"/>
  <rect id="left"        x="0"  y="6"  width="6"  height="48" fill="#162A57"/>
  <rect id="center"      x="6"  y="6"  width="48" height="48" fill="#162A57"/>
  <rect id="right"       x="54" y="6"  width="6"  height="48" fill="#162A57"/>
  <rect id="bottomleft"  x="0"  y="54" width="6"  height="6"  fill="#101F40"/>
  <rect id="bottom"      x="6"  y="54" width="48" height="6"  fill="#101F40"/>
  <rect id="bottomright" x="54" y="54" width="6"  height="6"  fill="#101F40"/>
</svg>
EOF

echo "== chroot hook: build PanmoxOS Plasma theme from breeze-dark + blue panel =="
mkdir -p config/hooks/normal
cat > config/hooks/normal/0950-panmox-plasma-theme.hook.chroot <<'EOF'
#!/bin/sh
SRC=""
for c in /usr/share/plasma/desktoptheme/breeze-dark /usr/share/plasma/desktoptheme/default; do
  [ -d "$c" ] && SRC="$c" && break
done
[ -z "$SRC" ] && exit 0
DST=/usr/share/plasma/desktoptheme/PanmoxOS
rm -rf "$DST"
cp -a "$SRC" "$DST"
# swap every panel-background variant for our blue one
find "$DST" -name 'panel-background.svg*' -print | while read f; do
  d=$(dirname "$f")
  rm -f "$d"/panel-background.svg*
  cp /usr/local/share/panmox/panel-background.svg "$d"/panel-background.svg
done
# rename in metadata (best effort)
[ -f "$DST/metadata.json" ] && sed -i 's/Breeze Dark/PanmoxOS/g' "$DST/metadata.json" 2>/dev/null || true
exit 0
EOF
chmod +x config/hooks/normal/0950-panmox-plasma-theme.hook.chroot

echo "== point Plasma theme at PanmoxOS (skel + LnF defaults) =="
SK="$INC/etc/skel/.config"
mkdir -p "$SK"
cat > "$SK/plasmarc" <<'EOF'
[Theme]
name=PanmoxOS
EOF

cat > "$LNF/contents/defaults" <<'EOF'
[kdeglobals][KDE]
LookAndFeelPackage=org.panmox.desktop
widgetStyle=Breeze

[kdeglobals][General]
ColorScheme=PanmoxOS

[kdeglobals][Icons]
Theme=Papirus-Dark

[plasmarc][Theme]
name=PanmoxOS

[kwinrc][org.kde.kdecoration2]
library=org.kde.breeze
theme=Breeze

[ksplashrc][KSplash]
Engine=KSplashQML
Theme=org.kde.breeze.desktop
EOF

echo "== first-login applier: also apply the blue Plasma theme =="
cat > "$INC/usr/local/bin/panmox-apply-theme.sh" <<'EOF'
#!/bin/sh
FLAG="$HOME/.config/panmox/.themed"
[ -f "$FLAG" ] && exit 0
plasma-apply-lookandfeel -a org.panmox.desktop 2>/dev/null
sleep 1
plasma-apply-desktoptheme PanmoxOS 2>/dev/null
plasma-apply-colorscheme PanmoxOS 2>/dev/null
plasma-apply-wallpaperimage /usr/share/wallpapers/PanmoxOS/contents/images/1920x1080.png 2>/dev/null
mkdir -p "$HOME/.config/panmox" && touch "$FLAG"
exit 0
EOF
chmod +x "$INC/usr/local/bin/panmox-apply-theme.sh"

echo "== layout: keep 1/3 dock, retry floating(true) =="
cat > "$LNF/contents/layouts/org.kde.plasma.desktop-layout.js" <<'EOF'
// PanmoxOS desktop layout v4
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

echo "BLUE THEME APPLY DONE"
