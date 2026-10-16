#!/bin/sh
# force plasmashell to reload the PanmoxOS theme (new blue panel svg)
U=panmox; PUID=$(id -u "$U")
EXP="export DISPLAY=:0; export XDG_RUNTIME_DIR=/run/user/$PUID; export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$PUID/bus;"

su - "$U" -c "$EXP plasma-apply-desktoptheme breeze-dark" 2>&1 || true
su - "$U" -c "rm -rf ~/.cache/plasma-svgelements* ~/.cache/plasma_theme* ~/.cache/icon-cache.kcache 2>/dev/null; true"
su - "$U" -c "$EXP plasma-apply-desktoptheme PanmoxOS" 2>&1 || true
# hard restart plasmashell so it re-reads the theme SVGs
su - "$U" -c "$EXP kquitapp5 plasmashell" 2>/dev/null || true
sleep 2
su - "$U" -c "$EXP kstart5 plasmashell" 2>/dev/null || true
echo "toggled + restarted; verifying panel svg exists:"
ls -l /usr/share/plasma/desktoptheme/PanmoxOS/widgets/panel-background.svg
