#!/usr/bin/env bash
set -euo pipefail
BUILD="${PMXOS_BUILD_DIR:?Set PMXOS_BUILD_DIR}"
cd "$BUILD"
INC=config/includes.chroot
LNF="$INC/usr/share/plasma/look-and-feel/org.panmox.desktop"

echo "== deps for the Hub (GTK WebKit) =="
cat > config/package-lists/pmxhub.list.chroot <<'EOF'
python3-gi
gir1.2-gtk-3.0
gir1.2-webkit2-4.1
EOF

echo "== Hub HTML =="
mkdir -p "$INC/usr/share/panmox/hub"
cat > "$INC/usr/share/panmox/hub/index.html" <<'HTML'
<!doctype html><html><head><meta charset="utf-8"><style>
:root{--bg:#080d1c;--bg2:#0c1430;--cyan:#3fe0ff;--ink:#eaf4ff;--mut:#8ea6c8;--pink:#ff2d7e;--card:#10193a;--line:#1d2c55}
*{box-sizing:border-box;margin:0;padding:0;font-family:'DejaVu Sans',sans-serif}
body{background:radial-gradient(60% 60% at 50% 35%,#11224a 0%,var(--bg) 70%);color:var(--ink);min-height:100vh;padding:48px 40px}
.brand{font-size:13px;letter-spacing:.5em;color:var(--cyan);text-transform:uppercase}
h1{font-size:54px;font-weight:800;margin:6px 0 2px} h1 .d{color:var(--pink)}
.sub{color:var(--mut);font-size:17px;margin-bottom:34px}
.row{display:grid;grid-template-columns:1fr 1fr;gap:18px;margin-bottom:26px}
.card{background:var(--card);border:1px solid var(--line);border-radius:16px;padding:22px 24px;cursor:pointer;transition:.15s;text-decoration:none;color:var(--ink);display:block}
.card:hover{border-color:var(--cyan);transform:translateY(-2px);box-shadow:0 8px 30px #0006}
.card h3{font-size:21px;margin-bottom:6px} .card p{color:var(--mut);font-size:14px;line-height:1.5}
.k{font-size:12px;letter-spacing:.25em;color:var(--cyan);text-transform:uppercase;margin-bottom:16px}
.apps{display:grid;grid-template-columns:repeat(4,1fr);gap:14px}
.app{background:var(--bg2);border:1px solid var(--line);border-radius:12px;padding:16px;text-align:center;text-decoration:none;color:var(--ink);font-size:14px;transition:.15s}
.app:hover{border-color:var(--cyan)} .app small{display:block;color:var(--mut);font-size:11px;margin-top:3px}
.foot{color:var(--mut);font-size:12px;margin-top:30px;text-align:center}
</style></head><body>
  <div class="brand">● PANMOX</div>
  <h1>PMX OS<span class="d">.</span></h1>
  <div class="sub">A peer-to-peer internet, in an operating system. <i>No cloud. No telemetry. No boss.</i></div>

  <div class="row">
    <a class="card" href="cmd:install"><h3>Install PMX OS →</h3><p>Put PMX OS on your disk. Runs the installer (UEFI, full disk or alongside).</p></a>
    <a class="card" href="cmd:altnet"><h3>Run a node · Browse .alt →</h3><p>Open AltNet Studio. Carry traffic for the network and browse .alt sites.</p></a>
  </div>

  <div class="k">The PANMOX catalog</div>
  <div class="apps">
    <a class="app" href="cmd:altnet">AltNet Studio<small>installed</small></a>
    <a class="app" href="https://panmox.org/">NeuralXP™<small>panmox.org</small></a>
    <a class="app" href="https://panmox.org/">PANMOX Browser™<small>panmox.org</small></a>
    <a class="app" href="https://panmox.org/">LostEngine™<small>panmox.org</small></a>
  </div>
  <div class="foot">PMX OS 0.1 “Phosphor” · Debian underneath · panmox.org</div>
</body></html>
HTML

echo "== Hub launcher (GTK WebKit) =="
mkdir -p "$INC/usr/local/bin"
cat > "$INC/usr/local/bin/pmx-hub" <<'PY'
#!/usr/bin/env python3
import gi, subprocess
gi.require_version('Gtk', '3.0'); gi.require_version('WebKit2', '4.1')
from gi.repository import Gtk, WebKit2, GLib
HTML = 'file:///usr/share/panmox/hub/index.html'
def run(c): subprocess.Popen(c, shell=True)
class Hub(Gtk.Window):
    def __init__(self):
        super().__init__(title="PMX Hub")
        self.set_default_size(1040, 720); self.set_position(Gtk.WindowPosition.CENTER)
        self.web = WebKit2.WebView(); self.web.load_uri(HTML)
        self.web.connect('decide-policy', self.policy)
        self.add(self.web); self.connect('destroy', Gtk.main_quit); self.show_all()
    def policy(self, web, decision, dtype):
        if dtype == WebKit2.PolicyDecisionType.NAVIGATION_ACTION:
            uri = decision.get_navigation_action().get_request().get_uri()
            if uri.startswith('cmd:'):
                self.cmd(uri[4:]); decision.ignore(); return True
            if uri.startswith('http'):
                run('xdg-open ' + GLib.shell_quote(uri)); decision.ignore(); return True
        return False
    def cmd(self, c):
        m = {'install':'pkexec calamares', 'altnet':'altnet-studio',
             'konsole':'konsole', 'settings':'systemsettings5'}
        if c in m: run(m[c])
Hub(); Gtk.main()
PY
chmod +x "$INC/usr/local/bin/pmx-hub"

# first-login wrapper (show once)
cat > "$INC/usr/local/bin/pmx-hub-firstrun" <<'EOF'
#!/bin/sh
F="$HOME/.config/panmox/.hub-shown"
[ -f "$F" ] && exit 0
mkdir -p "$HOME/.config/panmox"; touch "$F"
sleep 3; exec pmx-hub
EOF
chmod +x "$INC/usr/local/bin/pmx-hub-firstrun"

echo "== menu entry + first-login autostart =="
mkdir -p "$INC/usr/share/applications"
cat > "$INC/usr/share/applications/pmx-hub.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=PMX Hub
GenericName=Welcome
Comment=PMX OS welcome and control hub
Exec=pmx-hub
Icon=start-here-kde
Terminal=false
Categories=System;
EOF
mkdir -p "$INC/etc/skel/.config/autostart"
cat > "$INC/etc/skel/.config/autostart/pmx-hub.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=PMX Hub (first run)
Exec=pmx-hub-firstrun
X-KDE-autostart-phase=2
NoDisplay=true
EOF

echo "== pin PMX Hub in the dock (after AltNet) =="
LAY="$LNF/contents/layouts/org.kde.plasma.desktop-layout.js"
grep -q 'pmx-hub.desktop' "$LAY" || sed -i 's#"applications:altnet-studio.desktop",#"applications:altnet-studio.desktop",\n        "applications:pmx-hub.desktop",#' "$LAY"

echo "PMX HUB STAGED"
