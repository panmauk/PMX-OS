#!/bin/sh
F=/home/panmox/.config/plasma-org.kde.plasma.desktop-appletsrc
echo "=== panel containments / geometry ==="
grep -nE '^\[Containments\]\[[0-9]+\]\]?|location=|plugin=org.kde.panel|formfactor=|floating=|alignment=|minimumLength=|maximumLength=' "$F"
