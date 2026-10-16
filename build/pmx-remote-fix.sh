#!/bin/sh
# runs ON the VM as root; writes blue panel bg + applies theme to panmox session
T=/usr/share/plasma/desktoptheme/PanmoxOS
SVG='<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg" width="60" height="60" viewBox="0 0 60 60">
<rect id="topleft" x="0" y="0" width="6" height="6" fill="#274C86"/>
<rect id="top" x="6" y="0" width="48" height="6" fill="#274C86"/>
<rect id="topright" x="54" y="0" width="6" height="6" fill="#274C86"/>
<rect id="left" x="0" y="6" width="6" height="48" fill="#152A57"/>
<rect id="center" x="6" y="6" width="48" height="48" fill="#152A57"/>
<rect id="right" x="54" y="6" width="6" height="48" fill="#152A57"/>
<rect id="bottomleft" x="0" y="54" width="6" height="6" fill="#101F40"/>
<rect id="bottom" x="6" y="54" width="48" height="6" fill="#101F40"/>
<rect id="bottomright" x="54" y="54" width="6" height="6" fill="#101F40"/>
</svg>'
for d in widgets opaque/widgets translucent/widgets; do
  mkdir -p "$T/$d"
  printf '%s\n' "$SVG" > "$T/$d/panel-background.svg"
  rm -f "$T/$d/panel-background.svgz"
done

U=panmox; PUID=$(id -u "$U")
EXP="export DISPLAY=:0; export XDG_RUNTIME_DIR=/run/user/$PUID; export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$PUID/bus;"
su - "$U" -c "$EXP kwriteconfig5 --file plasmarc --group Theme --key name PanmoxOS"
su - "$U" -c "$EXP plasma-apply-desktoptheme PanmoxOS" 2>&1 || true
echo "REMOTE FIX applied; current plasma theme:"
su - "$U" -c "kreadconfig5 --file plasmarc --group Theme --key name"
