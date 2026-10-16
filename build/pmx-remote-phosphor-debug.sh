#!/bin/sh
U=panmox; PUID=$(id -u "$U")
EXP="export DISPLAY=:0 XAUTHORITY=/home/panmox/.Xauthority XDG_RUNTIME_DIR=/run/user/$PUID DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$PUID/bus;"
echo "themes (pmx):"; ls /usr/share/plasma/desktoptheme/ | grep -i pmx || echo NONE
echo "colorschemes:"; ls /usr/share/color-schemes/ | grep -iE 'Phosphor|PanmoxOS' || echo NONE
echo "green wallpaper:"; ls /usr/share/wallpapers/PMXPhosphor/contents/images/ 2>&1
echo "mode file:"; cat /home/panmox/.config/panmox/.mode 2>/dev/null || echo none
echo "--- apply phosphor (verbose) ---"
su - "$U" -c "$EXP plasma-apply-desktoptheme PMXPhosphor" 2>&1
su - "$U" -c "$EXP plasma-apply-colorscheme PMXPhosphor" 2>&1
su - "$U" -c "$EXP plasma-apply-wallpaperimage /usr/share/wallpapers/PMXPhosphor/contents/images/1920x1080.png" 2>&1
echo done
