#!/usr/bin/env python3
# Drive the QEMU guest via QMP: click/type/key/shot. Actions read from stdin, one per line.
import socket, json, sys, time
SOCK = "/tmp/pmx-ssh-qmp.sock"
W, H = 1280, 800
s = socket.socket(socket.AF_UNIX); s.connect(SOCK); f = s.makefile('rw'); f.readline()
def cmd(c, a=None):
    o = {"execute": c}
    if a: o["arguments"] = a
    f.write(json.dumps(o) + "\n"); f.flush()
    while True:
        m = json.loads(f.readline())
        if "return" in m or "error" in m: return m
cmd("qmp_capabilities")
def click(x, y):
    ax = int(int(x) / W * 32767); ay = int(int(y) / H * 32767)
    cmd("input-send-event", {"events": [{"type":"abs","data":{"axis":"x","value":ax}},
                                         {"type":"abs","data":{"axis":"y","value":ay}}]})
    time.sleep(0.2)
    cmd("input-send-event", {"events": [{"type":"btn","data":{"down":True,"button":"left"}}]})
    time.sleep(0.1)
    cmd("input-send-event", {"events": [{"type":"btn","data":{"down":False,"button":"left"}}]})
def key(k): cmd("send-key", {"keys": [{"type":"qcode","data":k}]})
def typ(t):
    sh = {'.':'dot','-':'minus','_':'minus','/':'slash',' ':'spc'}
    for ch in t:
        if ch.isalpha(): key(ch.lower())
        elif ch.isdigit(): key(ch)
        elif ch in sh: key(sh[ch])
        time.sleep(0.05)
def shot(p): cmd("screendump", {"filename": p, "format": "png"})
for line in sys.stdin:
    line = line.strip()
    if not line or line.startswith('#'): continue
    p = line.split()
    a = p[0]
    if a == "click": click(p[1], p[2])
    elif a == "key": key(p[1])
    elif a == "type": typ(" ".join(p[1:]))
    elif a == "sleep": time.sleep(float(p[1]))
    elif a == "shot": shot(p[1])
    sys.stderr.write("did: %s\n" % line)
print("DRIVE DONE")
