#!/bin/sh
U=panmox; PUID=$(id -u "$U")
EXP="export DISPLAY=:0; export XDG_RUNTIME_DIR=/run/user/$PUID; export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$PUID/bus;"
loginctl unlock-session 1 2>/dev/null || true
pkill -u "$U" -f kscreenlocker 2>/dev/null || true
sleep 1
if ! pgrep -u "$U" plasmashell >/dev/null; then
  su - "$U" -c "$EXP setsid plasmashell </dev/null >/dev/null 2>&1 &" || true
fi
sleep 3
pgrep -u "$U" plasmashell >/dev/null && echo "plasmashell running" || echo "plasmashell NOT running"
