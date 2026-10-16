#!/bin/sh
BR=/etc/calamares/branding/panmox
cp -f /tmp/cal-welcome.png "$BR/welcome.png" 2>/dev/null
cp -f /tmp/cal-welcome.png "$BR/slide1.png" 2>/dev/null
D="$BR/branding.desc"
sed -i 's#^\(\s*welcomeStyleCalamares:\).*#\1 false#' "$D"
[ -f "$BR/show.qml" ] && sed -i 's/Debian/PMX OS/g' "$BR/show.qml"
cp -f /tmp/partition.conf /etc/calamares/modules/partition.conf
echo "branding.desc welcome style + product:"
grep -E 'welcomeStyleCalamares|productName' "$D" | head
pkill -x calamares 2>/dev/null; sleep 1
DISPLAY=:0 XAUTHORITY=/home/panmox/.Xauthority setsid calamares >/tmp/cal.log 2>&1 &
sleep 10
pgrep -x calamares >/dev/null && echo "calamares running" || { echo "FAILED"; tail -6 /tmp/cal.log; }
