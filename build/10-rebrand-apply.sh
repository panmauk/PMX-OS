#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
A="${PMXOS_ASSETS_DIR:?Set PMXOS_ASSETS_DIR}"
IM=magick; command -v magick >/dev/null 2>&1 || IM=convert
[ -f "$A/wallpaper_1920.png" ] || { echo "assets missing - run 09 first"; exit 1; }

echo "== host: ensure rsvg (rasterizes boot splash) =="
command -v rsvg-convert >/dev/null 2>&1 || { apt-get install -y --no-install-recommends librsvg2-bin >/dev/null; }

echo "== derive 800x600 boot splash (4:3, for grub/isolinux) =="
$IM "$A/boot_640.png" -resize 800x600 "$A/boot_800.png"

cd "$BUILD"
INC=config/includes.chroot
BL=config/bootloaders

# ---------------------------------------------------------------------------
# 1) WALLPAPER package
# ---------------------------------------------------------------------------
WP="$INC/usr/share/wallpapers/PanmoxOS"
mkdir -p "$WP/contents/images"
cp -f "$A/wallpaper_1920.png" "$WP/contents/images/1920x1080.png"
cp -f "$A/wallpaper_1920.png" "$WP/contents/screenshot.png"
cat > "$WP/metadata.desktop" <<'EOF'
[Desktop Entry]
Name=PanmoxOS
X-KDE-PluginInfo-Name=PanmoxOS
X-KDE-PluginInfo-Author=PANMOX
[Wallpaper]
defaultWidth=1920
defaultHeight=1080
EOF

# ---------------------------------------------------------------------------
# 2) COLOR SCHEME (dark indigo, cyan accent, pink highlight)
# ---------------------------------------------------------------------------
mkdir -p "$INC/usr/share/color-schemes"
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
activeBackground=14,20,36
activeForeground=234,247,255
inactiveBackground=12,17,30
inactiveForeground=130,150,180
activeBlend=63,224,255
EOF

# ---------------------------------------------------------------------------
# 3) /etc/skel KDE defaults (dark + accent immediately; autostart applies the rest)
# ---------------------------------------------------------------------------
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

[Icons]
Theme=breeze-dark
EOF

cat > "$SK/kscreenlockerrc" <<'EOF'
[Greeter][Wallpaper][org.kde.image][General]
Image=/usr/share/wallpapers/PanmoxOS/contents/images/1920x1080.png
EOF

# first-login theme applier (robust, version-tolerant)
mkdir -p "$INC/usr/local/bin"
cat > "$INC/usr/local/bin/panmox-apply-theme.sh" <<'EOF'
#!/bin/sh
FLAG="$HOME/.config/panmox/.themed"
[ -f "$FLAG" ] && exit 0
plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null
sleep 1
plasma-apply-colorscheme PanmoxOS 2>/dev/null
plasma-apply-wallpaperimage /usr/share/wallpapers/PanmoxOS/contents/images/1920x1080.png 2>/dev/null
mkdir -p "$HOME/.config/panmox" && touch "$FLAG"
exit 0
EOF
chmod +x "$INC/usr/local/bin/panmox-apply-theme.sh"
mkdir -p "$SK/autostart"
cat > "$SK/autostart/panmox-theme.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=PanmoxOS Theme
Exec=/usr/local/bin/panmox-apply-theme.sh
X-KDE-autostart-phase=2
NoDisplay=true
EOF

# ---------------------------------------------------------------------------
# 4) SDDM login screen background (breeze theme override)
# ---------------------------------------------------------------------------
SDDM="$INC/usr/share/sddm/themes/breeze"
mkdir -p "$SDDM"
cp -f "$A/wallpaper_1920.png" "$SDDM/panmox-bg.png"
cat > "$SDDM/theme.conf.user" <<'EOF'
[General]
type=image
background=/usr/share/sddm/themes/breeze/panmox-bg.png
EOF
mkdir -p "$INC/etc/sddm.conf.d"
cat > "$INC/etc/sddm.conf.d/panmox.conf" <<'EOF'
[Theme]
Current=breeze
EOF

# ---------------------------------------------------------------------------
# 5) PLYMOUTH boot splash (script theme = our background fullscreen)
# ---------------------------------------------------------------------------
PLY="$INC/usr/share/plymouth/themes/panmox"
mkdir -p "$PLY"
cp -f "$A/wallpaper_1920.png" "$PLY/background.png"
cat > "$PLY/panmox.plymouth" <<'EOF'
[Plymouth Theme]
Name=PanmoxOS
Description=PanmoxOS boot splash
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/panmox
ScriptFile=/usr/share/plymouth/themes/panmox/panmox.script
EOF
cat > "$PLY/panmox.script" <<'EOF'
bg = Image("background.png");
sw = Window.GetWidth();
sh = Window.GetHeight();
scaled = bg.Scale(sw, sh);
sprite = Sprite(scaled);
sprite.SetX(0); sprite.SetY(0); sprite.SetZ(-100);

fun refresh_cb() { }
Plymouth.SetRefreshFunction(refresh_cb);
EOF
# hook: make panmox the default plymouth theme, rebuild initramfs (non-fatal)
mkdir -p config/hooks/normal
cat > config/hooks/normal/0900-panmox-plymouth.hook.chroot <<'EOF'
#!/bin/sh
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
  plymouth-set-default-theme panmox >/dev/null 2>&1 || true
  update-initramfs -u >/dev/null 2>&1 || true
fi
exit 0
EOF
chmod +x config/hooks/normal/0900-panmox-plymouth.hook.chroot

# packages needed for the above
cat > config/package-lists/branding.list.chroot <<'EOF'
plymouth
plymouth-label
EOF

# ---------------------------------------------------------------------------
# 6) BOOTLOADERS — auto-boot timeout + PanmoxOS splash + cyan menu (BIOS+UEFI)
# ---------------------------------------------------------------------------
# 6a) shared splash art (rasterized to splash.png -> background for BOTH menus)
mkdir -p "$BL/syslinux_common"
b64=$(base64 -w0 "$A/boot_800.png")
{
  printf '%s' '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="800" height="600" viewBox="0 0 800 600">'
  printf '%s' "<image width=\"800\" height=\"600\" xlink:href=\"data:image/png;base64,$b64\"/>"
  printf '%s' '</svg>'
} > "$BL/syslinux_common/splash.svg"

# 6b) isolinux (BIOS): auto-boot after 5s
mkdir -p "$BL/isolinux"
cat > "$BL/isolinux/isolinux.cfg" <<'EOF'
include menu.cfg
default vesamenu.c32
prompt 0
timeout 50
EOF

# 6c) syslinux menu title + cyan colors (AARRGGBB)
cat > "$BL/syslinux_common/menu.cfg" <<'EOF'
menu hshift 0
menu width 82

menu title PanmoxOS
include stdmenu.cfg
include live.cfg
@OPTIONAL_INSTALLER_INCLUDE@
menu begin utilities
	menu label ^Utilities
	menu title Utilities
	include stdmenu.cfg
	label mainmenu
		menu label ^Back..
		menu exit
	include utilities.cfg
menu end

menu clear
EOF
cat > "$BL/syslinux_common/stdmenu.cfg" <<'EOF'
menu background splash.png
menu color title	* #FF7FE9FF #00000000 *
menu color border	* #00000000 #00000000 none
menu color sel		* #FF06090F #FF7FE9FF *
menu color unsel	* #FFCFE9FF #00000000 *
menu color hotsel	1;7;37;40 #FF06090F #FF7FE9FF *
menu color hotkey	1;37;40 #FF7FE9FF #00000000 *
menu color tabmsg	* #FF7FE9FF #00000000 *
menu color help		37;40 #FFAFC8E0 #00000000 none
menu vshift 14
menu rows 8
menu helpmsgrow 15
menu cmdlinerow 16
menu timeoutrow 16
menu tabmsgrow 18
menu tabmsg Press ENTER to boot PanmoxOS
EOF

# 6d) grub (UEFI): add timeout, cyan theme, drop Debian title text
mkdir -p "$BL/grub-pc/live-theme"
cat > "$BL/grub-pc/config.cfg" <<'EOF'
set default=0
set timeout=5
set timeout_style=menu

if [ x$feature_default_font_path = xy ] ; then
    font=unicode
else
    font=$prefix/unicode.pf2
fi

if loadfont $font ; then
    set gfxmode=800x600
    set gfxpayload=keep
    insmod efi_gop
    insmod efi_uga
    insmod video_bochs
    insmod video_cirrus
else
    set gfxmode=auto
    insmod all_video
fi

insmod gfxterm
insmod png

source /boot/grub/theme.cfg

terminal_output gfxterm
EOF
cat > "$BL/grub-pc/live-theme/theme.txt" <<'EOF'
desktop-image: "../splash.png"
title-color: "#7FE9FF"
title-font: "Unifont Regular 16"
title-text: ""
message-font: "Unifont Regular 16"
terminal-font: "Unifont Regular 16"

+ label {
        top = 100%-50
        left = 0
        width = 100%
        height = 20
        text = "@KEYMAP_SHORT@"
        align = "center"
        color = "#7FE9FF"
        font = "Unifont Regular 16"
}

+ boot_menu {
        left = 12%
        width = 76%
        top = 58%
        height = 42%-80
        item_color = "#AFC8E0"
        item_font = "Unifont Regular 16"
        selected_item_color = "#FFFFFF"
        selected_item_font = "Unifont Regular 16"
        item_height = 18
        item_padding = 2
        item_spacing = 4
        icon_width = 0
        icon_heigh = 0
        item_icon_space = 0
}

+ progress_bar {
        id = "__timeout__"
        left = 15%
        top = 100%-80
        height = 14
        width = 70%
        font = "Unifont Regular 16"
        text_color = "#06090F"
        fg_color = "#7FE9FF"
        bg_color = "#1A2336"
        border_color = "#7FE9FF"
        text = "@TIMEOUT_NOTIFICATION_LONG@"
}
EOF

echo "== rebrand files written =="
find "$INC" "$BL" config/hooks config/package-lists/branding.list.chroot -type f 2>/dev/null | sort
echo "REBRAND APPLY DONE"
