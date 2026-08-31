#!/usr/bin/env python3
"""Generates the two design mockups as standalone SVG files."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_assets import GLYPHS, STROKE_GLYPHS, APPS, APP, icon_svg, PREVIEW

FONT = "Inter, 'Segoe UI', 'Helvetica Neue', Arial, sans-serif"

def glyph_group(app_id, cx, cy, gsize, fill="#ffffff"):
    gs = gsize / 24.0
    ox, oy = cx - gsize / 2, cy - gsize / 2
    d, eo = GLYPHS[app_id]
    fr = ' fill-rule="evenodd"' if eo else ""
    s = f'<g transform="translate({ox:.1f} {oy:.1f}) scale({gs:.4f})">'
    s += f'<path d="{d}" fill="{fill}"{fr}/>'
    if app_id in STROKE_GLYPHS:
        s += f'<path d="{STROKE_GLYPHS[app_id]}" fill="none" stroke="{fill}" stroke-width="1.7" stroke-linecap="round"/>'
    return s + "</g>"

def app_icon(app_id, x, y, size, rid):
    _, _, c1, c2 = APP[app_id]
    r = size * 0.225
    gsize = size * 0.56
    return f'''<defs><linearGradient id="{rid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/></linearGradient></defs>
<rect x="{x:.1f}" y="{y:.1f}" width="{size}" height="{size}" rx="{r:.1f}" fill="url(#{rid})"/>
<rect x="{x:.1f}" y="{y:.1f}" width="{size}" height="{size*0.5:.1f}" rx="{r:.1f}" fill="#ffffff" opacity="0.14"/>
{glyph_group(app_id, x + size/2, y + size/2 + size*0.015, gsize)}'''

DEVICE_DEFS = f'''
<defs>
<radialGradient id="bg" cx="50%" cy="38%" r="85%"><stop offset="0" stop-color="#20242f"/><stop offset="1" stop-color="#0b0d12"/></radialGradient>
<linearGradient id="frame" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#3a4050"/><stop offset="0.5" stop-color="#181b23"/><stop offset="1" stop-color="#2c313d"/></linearGradient>
<filter id="soft" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="60"/></filter>
<filter id="soft2" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="26"/></filter>
<linearGradient id="wallbase" x1="0" y1="0" x2="0.6" y2="1"><stop offset="0" stop-color="#101728"/><stop offset="0.55" stop-color="#0d1322"/><stop offset="1" stop-color="#0a0e1a"/></linearGradient>
<radialGradient id="blobA" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#14b8a6" stop-opacity="0.5"/><stop offset="1" stop-color="#14b8a6" stop-opacity="0"/></radialGradient>
<radialGradient id="blobB" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#6366f1" stop-opacity="0.55"/><stop offset="1" stop-color="#6366f1" stop-opacity="0"/></radialGradient>
<radialGradient id="blobC" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#db2777" stop-opacity="0.32"/><stop offset="1" stop-color="#db2777" stop-opacity="0"/></radialGradient>
<radialGradient id="sheen" cx="30%" cy="0%" r="90%"><stop offset="0" stop-color="#ffffff" stop-opacity="0.10"/><stop offset="0.45" stop-color="#ffffff" stop-opacity="0.02"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></radialGradient>
<linearGradient id="dockg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff" stop-opacity="0.17"/><stop offset="1" stop-color="#ffffff" stop-opacity="0.09"/></linearGradient>
<clipPath id="screenclip"><rect x="206" y="246" width="448" height="1008" rx="48"/></clipPath>
</defs>'''

def device_shell(inner_svg):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="860" height="1500" viewBox="0 0 860 1500">
{DEVICE_DEFS}
<rect width="860" height="1500" fill="url(#bg)"/>
<ellipse cx="430" cy="700" rx="420" ry="520" fill="#1d4ed8" opacity="0.10" filter="url(#soft)"/>
<ellipse cx="250" cy="520" rx="300" ry="380" fill="#0d9488" opacity="0.10" filter="url(#soft)"/>
<ellipse cx="430" cy="1290" rx="330" ry="60" fill="#000000" opacity="0.55" filter="url(#soft2)"/>
<!-- side buttons -->
<rect x="663" y="430" width="6" height="72" rx="3" fill="#3a4152"/>
<rect x="663" y="520" width="6" height="72" rx="3" fill="#3a4152"/>
<rect x="663" y="620" width="6" height="104" rx="3" fill="#414859"/>
<rect x="191" y="470" width="6" height="96" rx="3" fill="#3a4152"/>
<!-- frame -->
<rect x="195" y="235" width="470" height="1030" rx="58" fill="url(#frame)"/>
<rect x="198" y="238" width="464" height="1024" rx="55" fill="#0a0c11"/>
{inner_svg}
</svg>'''

def status_bar(chat_mode=False):
    y = 292
    return f'''
<text x="240" y="{y}" font-family="{FONT}" font-size="22" font-weight="600" fill="#ffffff">9:41</text>
<g fill="#ffffff">
<rect x="540" y="{y-14}" width="4" height="6" rx="1.5" opacity="0.95"/>
<rect x="547" y="{y-17}" width="4" height="9" rx="1.5" opacity="0.95"/>
<rect x="554" y="{y-20}" width="4" height="12" rx="1.5" opacity="0.95"/>
<rect x="561" y="{y-23}" width="4" height="15" rx="1.5" opacity="0.95"/>
</g>
<text x="572" y="{y-2}" font-family="{FONT}" font-size="12" font-weight="600" fill="#ffffff" opacity="0.92">AURA</text>
<g>
<rect x="614" y="{y-17}" width="30" height="15" rx="4.5" fill="none" stroke="#ffffff" stroke-opacity="0.5" stroke-width="1.6"/>
<rect x="616.5" y="{y-14.5}" width="21" height="10" rx="2.5" fill="#ffffff"/>
<rect x="645.5" y="{y-11.5}" width="2.6" height="6.5" rx="1.3" fill="#ffffff" opacity="0.55"/>
</g>'''

# ------------------------------------------------------------ mockup 1 -----
GRID = ["contacts", "messages", "gallery", "bank", "settings", "notes", "vehicles", "properties", "jobs", "emergency", "weather", "notifications"]
DOCK = ["calls", "maps", "camera", "store"]

def home_screen():
    s = f'''<g clip-path="url(#screenclip)">
<rect x="206" y="246" width="448" height="1008" fill="url(#wallbase)"/>
<ellipse cx="330" cy="430" rx="270" ry="240" fill="url(#blobA)"/>
<ellipse cx="610" cy="820" rx="300" ry="280" fill="url(#blobB)"/>
<ellipse cx="320" cy="1120" rx="260" ry="220" fill="url(#blobC)"/>
<rect x="206" y="246" width="448" height="1008" fill="url(#sheen)"/>
{status_bar()}
<rect x="402" y="266" width="110" height="30" rx="15" fill="#05070c"/>
<circle cx="484" cy="281" r="5.5" fill="#10141f"/><circle cx="485.5" cy="279.5" r="1.6" fill="#2b3a55"/>
'''
    x0, step, y0, rstep, size = 240, 96.67, 408, 124, 86
    for i, app_id in enumerate(GRID):
        x = x0 + (i % 4) * step
        y = y0 + (i // 4) * rstep
        s += app_icon(app_id, x, y, size, f"mi{i}")
        s += f'<text x="{x + size/2:.1f}" y="{y + size + 21:.1f}" text-anchor="middle" font-family="{FONT}" font-size="13" fill="#ffffff" opacity="0.88">{APP[app_id][1]}</text>'
    # page dots
    for i in range(2):
        s += f'<circle cx="{418 + i*20}" cy="812" r="4" fill="#ffffff" opacity="{0.9 if i==0 else 0.35}"/>'
    # dock
    s += f'<rect x="228" y="968" width="404" height="118" rx="34" fill="url(#dockg)" stroke="#ffffff" stroke-opacity="0.10"/>'
    for i, app_id in enumerate(DOCK):
        x = 258 + i * 101
        s += app_icon(app_id, x, 993, 78, f"dk{i}")
    # home indicator
    s += '<rect x="365" y="1228" width="130" height="5" rx="2.5" fill="#ffffff" opacity="0.85"/>'
    s += "</g>"
    return s

# ------------------------------------------------------------ mockup 2 -----
def wrap(text, maxchars=33):
    words, lines, cur = text.split(), [], ""
    for wd in words:
        if cur and len(cur) + 1 + len(wd) > maxchars:
            lines.append(cur); cur = wd
        else:
            cur = (cur + " " + wd).strip()
    if cur: lines.append(cur)
    return lines

def bubble(text, mine, time, checks=False, y0=448):
    lines = wrap(text, 33)
    w = min(312, max(len(l) for l in lines) * 8.0 + 34)
    h = len(lines) * 23 + 24
    r = 17
    if mine:
        x = 616 - w
        fill = "#ffffff"
        body = f'<rect x="{x:.0f}" y="{y0}" width="{w:.0f}" height="{h:.0f}" rx="{r}" fill="url(#bubme)"/>'
        tail = f'<path d="M{x+w:.0f} {y0+h} l -9 0 q 3 -9 9 -9 z" fill="url(#bubme)"/>'
    else:
        x = 244
        fill = "#e9edf6"
        body = f'<rect x="{x}" y="{y0}" width="{w:.0f}" height="{h:.0f}" rx="{r}" fill="#1c2230"/>'
        tail = f'<path d="M{x:.0f} {y0+h} l 9 0 q -3 -9 -9 -9 z" fill="#1c2230"/>'
    s = body + tail
    for i, ln in enumerate(lines):
        s += f'<text x="{x + 17:.0f}" y="{y0 + 21 + i*23}" font-family="{FONT}" font-size="15" fill="{fill}">{ln}</text>'
    ct = "#8b93a7" if not mine else "rgba(255,255,255,0.7)"
    ty = y0 + h + 15
    s += f'<text x="{x + 17:.0f}" y="{ty}" font-family="{FONT}" font-size="10.5" fill="{ct}">{time}</text>'
    if checks:
        cx = x + 17 + len(time) * 5.9 + 8
        s += f'''<g stroke="rgba(255,255,255,0.95)" stroke-width="1.7" fill="none" stroke-linecap="round" stroke-linejoin="round">
<path d="M{cx:.0f} {ty-3.5} l 3.5 3.5 l 6 -7"/><path d="M{cx+9:.0f} {ty-3.5} l 3.5 3.5 l 6 -7"/></g>'''
    return s, h + 40

def chat_screen():
    s = '''<g clip-path="url(#screenclip)">
<rect x="206" y="246" width="448" height="1008" fill="#0d1017"/>
<rect x="206" y="246" width="448" height="300" fill="#131a29" opacity="0.5"/>
'''
    s += status_bar()
    # header
    s += '''<path d="M258 322 l -14 12 l 14 12" fill="none" stroke="#ffffff" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>
<circle cx="300" cy="334" r="21" fill="url(#avgrad)"/>
<text x="300" y="339.5" text-anchor="middle" font-family="''' + FONT + '''" font-size="14" font-weight="700" fill="#ffffff">NK</text>
<circle cx="315" cy="319" r="7.5" fill="#ef4444" stroke="#0d1017" stroke-width="2"/>
<text x="315" y="322.5" text-anchor="middle" font-family="''' + FONT + '''" font-size="9.5" font-weight="700" fill="#fff">2</text>
<text x="334" y="330" font-family="''' + FONT + '''" font-size="17" font-weight="600" fill="#ffffff">Nadia Karim</text>
<text x="334" y="350" font-family="''' + FONT + '''" font-size="12" fill="#34d399">Online</text>
<line x1="206" y1="368" x2="654" y2="368" stroke="#ffffff" stroke-opacity="0.07"/>'''
    s += '<circle cx="600" cy="334" r="17" fill="#ffffff" opacity="0.08"/>'
    s += glyph_group("calls", 600, 334, 18)
    s += '<circle cx="636" cy="334" r="17" fill="#ffffff" opacity="0.08"/>'
    s += glyph_group("camera", 636, 334, 17)
    # date chip
    s += f'<rect x="352" y="396" width="156" height="28" rx="14" fill="#ffffff" opacity="0.06"/><text x="430" y="414.5" text-anchor="middle" font-family="{FONT}" font-size="12" fill="#8b93a7">Today 9:41</text>'
    msgs = [
        ("Hey! Are we still on for the meetup tonight?", False, "9:41 AM"),
        ("The bank closed early, don't forget your transfer.", False, "9:42 AM"),
        ("Yes! I'll pick you up at the mall in 10 minutes.", True, "9:42 AM"),
        ("Perfect. Check your messages when you land.", False, "9:43 AM"),
        ("Already done. Car's ready, see you soon.", True, "9:43 AM", True),
    ]
    y = 448
    for m in msgs:
        text, mine, t = m[0], m[1], m[2]
        checks = m[3] if len(m) > 3 else False
        bs, step = bubble(text, mine, t, checks, y)
        s += bs
        y += step
    # typing indicator
    s += '<rect x="244" y="1022" width="64" height="40" rx="18" fill="#1c2230"/>'
    for i in range(3):
        s += f'<circle cx="{266 + i*16}" cy="1042" r="4" fill="#6b7484" opacity="{0.4+0.3*i}"/>'
    # composer
    s += '''<rect x="240" y="1128" width="330" height="56" rx="28" fill="#151b26" stroke="#ffffff" stroke-opacity="0.08"/>
<text x="272" y="1162" font-family="''' + FONT + '''" font-size="15" fill="#5d667a">Message</text>
<circle cx="612" cy="1156" r="27" fill="url(#sendgrad)"/>
<path d="M600 1156 l 24 -9 l -10 20 l -3 -8 z" fill="#ffffff"/>
<rect x="365" y="1228" width="130" height="5" rx="2.5" fill="#ffffff" opacity="0.85"/>
</g>
<defs><linearGradient id="bubme" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#22c55e"/><stop offset="1" stop-color="#15803d"/></linearGradient>
<linearGradient id="avgrad" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#22d3ee"/><stop offset="1" stop-color="#6366f1"/></linearGradient>
<linearGradient id="sendgrad" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#22c55e"/><stop offset="1" stop-color="#15803d"/></linearGradient></defs>'''
    return s

# the inner_svg for chat needs the extra defs BEFORE first use; simplest: inject defs right after clip
inner_chat = chat_screen().replace('<rect x="206" y="246" width="448" height="1008" fill="#0d1017"/>',
    '<defs><linearGradient id="bubme" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#22c55e"/><stop offset="1" stop-color="#15803d"/></linearGradient><linearGradient id="avgrad" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#22d3ee"/><stop offset="1" stop-color="#6366f1"/></linearGradient><linearGradient id="sendgrad" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#22c55e"/><stop offset="1" stop-color="#15803d"/></linearGradient></defs><rect x="206" y="246" width="448" height="1008" fill="#0d1017"/>')
open(os.path.join(PREVIEW, "phone_mockup.svg"), "w").write(device_shell(home_screen()))
open(os.path.join(PREVIEW, "messages_screen.svg"), "w").write(device_shell(inner_chat))
print("mockups ok")
