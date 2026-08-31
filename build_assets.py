#!/usr/bin/env python3
"""Asset builder for the AURA phone MTA:SA resource.
Generates: icons (SVG + transparent PNG), UI textures, WAV sounds,
two design mockups (home-screen device mockup + messaging screen) as SVG,
and a contact sheet preview.
"""
import math, os, struct, wave, cairosvg
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(ROOT, "assets")
ICONS = os.path.join(ASSETS, "icons")
WALL = os.path.join(ASSETS, "wallpapers")
SOUNDS = os.path.join(ASSETS, "sounds")
UI = os.path.join(ASSETS, "ui")
PREVIEW = os.path.join(os.path.dirname(ROOT), "preview")
for d in (ICONS, WALL, SOUNDS, UI, PREVIEW):
    os.makedirs(d, exist_ok=True)

# ---------------------------------------------------------------- icons ----
# glyph space: 24x24, y-down. items: ("p", d, evenodd?) or ("s", d, width)
GLYPHS = {
"calls": ("M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.21c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z", 0),
"contacts": ("M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z", 0),
"messages": ("M20 2H4a2 2 0 0 0-2 2v18l4-4h14a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2zm-2 12H6v-2h12v2zm0-3H6V9h12v2zm0-3H6V6h12v2z", 1),
"camera": ("M8.5 5h7c.5 0 .97.25 1.25.67L18.2 7.7H19a2 2 0 0 1 2 2V17a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9.7a2 2 0 0 1 2-2h.8l1.45-2.03A1.5 1.5 0 0 1 8.5 5zM12 9.25a3.75 3.75 0 1 0 0 7.5 3.75 3.75 0 0 0 0-7.5z", 1),
"gallery": ("M4.5 5.5h15A1.5 1.5 0 0 1 21 7v10a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 17V7a1.5 1.5 0 0 1 1.5-1.5zM4.5 7.5V17h15V7.5h-15z M8.75 9.25a1.9 1.9 0 1 0 0 3.8 1.9 1.9 0 0 0 0-3.8z M4.5 15.6l3.9-4.7 3 3.55 3.4-4.15 4.2 5.3v1.4h-15v-1.4z", 1),
"maps": ("M12 2.5c-4.14 0-7.5 3.36-7.5 7.5 0 5.36 7.5 11.5 7.5 11.5s7.5-6.14 7.5-11.5c0-4.14-3.36-7.5-7.5-7.5zm0 4.75a2.75 2.75 0 1 0 0 5.5 2.75 2.75 0 0 0 0-5.5z", 1),
"bank": ("M12 3L2 8.8h20L12 3z M4 10.8h3.2v7.2H4z M10.4 10.8h3.2v7.2h-3.2z M16.8 10.8h3.2v7.2h-3.2z M2.5 19.8h19v2.7h-19z", 0),
"settings": ("M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6A3.61 3.61 0 1 1 12 8.4a3.61 3.61 0 0 1 0 7.2z", 0),
"notifications": ("M12 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6-6v-5c0-3.07-1.64-5.64-4.5-6.32V4a1.5 1.5 0 0 0-3 0v.68C7.64 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2z", 0),
"notes": ("M6 2.5h12A1.5 1.5 0 0 1 19.5 4v16a1.5 1.5 0 0 1-1.5 1.5H6A1.5 1.5 0 0 1 4.5 20V4A1.5 1.5 0 0 1 6 2.5zm1 5h10v2H7zm0 4h10v2H7zm0 4h6v2H7z", 1),
"vehicles": ("M7.2 10L8.5 6.6A1.8 1.8 0 0 1 10.2 5.4h3.6a1.8 1.8 0 0 1 1.7 1.2L16.8 10H7.2zM2.5 10.5A1.5 1.5 0 0 1 4 9h16a1.5 1.5 0 0 1 1.5 1.5v5A1.5 1.5 0 0 1 20 17H4a1.5 1.5 0 0 1-1.5-1.5v-5zM7 14.8a2.4 2.4 0 1 0 0 4.8 2.4 2.4 0 0 0 0-4.8zm0 1.4a1 1 0 1 1 0 2 1 1 0 0 1 0-2z M17 14.8a2.4 2.4 0 1 0 0 4.8 2.4 2.4 0 0 0 0-4.8zm0 1.4a1 1 0 1 1 0 2 1 1 0 0 1 0-2z", 1),
"properties": ("M12 3.3L20.7 11h-2.2v7.5A1.5 1.5 0 0 1 17 20h-3.4v-4.6a1.6 1.6 0 0 0-3.2 0V20H7a1.5 1.5 0 0 1-1.5-1.5V11H3.3L12 3.3z", 0),
"jobs": ("M8.7 3.5h6.6c.55 0 1 .45 1 1v3h-2V5.6H9.7v1.9h-2v-3c0-.55.45-1 1-1zM3.5 9.5h17c.8 0 1.5.7 1.5 1.5v8.5c0 .8-.7 1.5-1.5 1.5h-17C2.7 21 2 20.3 2 19.5V11c0-.8.7-1.5 1.5-1.5zm7 3v3h3v-3h-3z", 1),
"emergency": ("M9.4 3.5h5.2c.55 0 1 .45 1 1v4.1h4.1c.55 0 1 .45 1 1v5.2c0 .55-.45 1-1 1h-4.1v4.1c0 .55-.45 1-1 1H9.4c-.55 0-1-.45-1-1v-4.1H4.3c-.55 0-1-.45-1-1V9.6c0-.55.45-1 1-1h4.1V4.5c0-.55.45-1 1-1z", 0),
"store": ("M4.7 9h14.6c.6 0 1.1.5 1 1.1l-1.1 9.6a2 2 0 0 1-2 1.8H6.8a2 2 0 0 1-2-1.8L3.7 10.1c-.1-.6.4-1.1 1-1.1z M8.6 9V7.2a3.4 3.4 0 0 1 6.8 0V9", 0),
"weather": ("M12 7.25a4.75 4.75 0 1 0 0 9.5 4.75 4.75 0 0 0 0-9.5z M12 2.75v2.5M12 18.75v2.5M2.75 12h2.5M18.75 12h2.5M5.4 5.4l1.8 1.8M16.8 16.8l1.8 1.8M18.6 5.4l-1.8 1.8M7.2 16.8l-1.8 1.8", 0),
}
# store handle + weather rays are stroked: separate entries
STROKE_GLYPHS = {
    "store": "M8.6 9V7.2a3.4 3.4 0 0 1 6.8 0V9",
    "weather": "M12 2.75v2.5M12 18.75v2.5M2.75 12h2.5M18.75 12h2.5M5.4 5.4l1.8 1.8M16.8 16.8l1.8 1.8M18.6 5.4l-1.8 1.8M7.2 16.8l-1.8 1.8",
}

APPS = [  # id, label, color top, color bottom
    ("calls",        "Phone",        "#34d399", "#059669"),
    ("contacts",     "Contacts",     "#60a5fa", "#2563eb"),
    ("messages",     "Messages",     "#22d3ee", "#0e7490"),
    ("camera",       "Camera",       "#94a3b8", "#475569"),
    ("gallery",      "Photos",       "#fbbf24", "#d97706"),
    ("maps",         "Maps",         "#2dd4bf", "#0f766e"),
    ("bank",         "Bank",         "#818cf8", "#4338ca"),
    ("settings",     "Settings",     "#a78bfa", "#7c3aed"),
    ("notifications","Alerts",       "#fb7185", "#e11d48"),
    ("notes",        "Notes",        "#fb923c", "#ea580c"),
    ("vehicles",     "Garage",       "#e879f9", "#a21caf"),
    ("properties",   "Homes",        "#e8b878", "#a06a2c"),
    ("jobs",         "Jobs",         "#a3e635", "#65a30d"),
    ("emergency",    "Emergency",    "#f87171", "#b91c1c"),
    ("store",        "App Store",    "#f472b6", "#be185d"),
    ("weather",      "Server",       "#53b9ff", "#1d7fd1"),
]
APP = {a[0]: a for a in APPS}

def glyph_svg(app_id, scale, ox, oy, gid, fill="#ffffff", stroke_color="#ffffff"):
    parts = []
    d, eo = GLYPHS[app_id]
    fr = ' fill-rule="evenodd"' if eo else ""
    parts.append(f'<path d="{d}" fill="{fill}"{fr}/>')
    if app_id in STROKE_GLYPHS:
        parts.append(f'<path d="{STROKE_GLYPHS[app_id]}" fill="none" stroke="{stroke_color}" stroke-width="1.7" stroke-linecap="round"/>')
    return f'<g transform="translate({ox:.2f} {oy:.2f}) scale({scale:.4f})">' + "".join(parts) + "</g>"

def icon_svg(app_id, size=256):
    _, _, c1, c2 = APP[app_id]
    inset = size * 0.094          # 24/256
    r = size * 0.195
    gsize = size * 0.53
    gs = gsize / 24.0
    gx = (size - gsize) / 2.0
    cy = size / 2 - size * 0.03   # optical center slightly high
    gy = cy - gsize / 2.0
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}">
<defs>
<linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/></linearGradient>
<linearGradient id="sh" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff" stop-opacity="0.35"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></linearGradient>
<filter id="bl" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation="{size*0.038:.2f}"/></filter>
</defs>
<rect x="{inset}" y="{inset + size*0.055}" width="{size-2*inset}" height="{size-2*inset}" rx="{r}" fill="#000000" opacity="0.32" filter="url(#bl)"/>
<rect x="{inset}" y="{inset}" width="{size-2*inset}" height="{size-2*inset}" rx="{r}" fill="url(#g)"/>
<rect x="{inset}" y="{inset}" width="{size-2*inset}" height="{size*0.52}" rx="{r}" fill="url(#sh)"/>
{glyph_svg(app_id, gs, gx, gy, app_id)}
</svg>'''

for app_id, label, c1, c2 in APPS:
    svg = icon_svg(app_id)
    with open(os.path.join(ICONS, f"{app_id}.svg"), "w") as f:
        f.write(svg)
    cairosvg.svg2png(bytestring=svg.encode(), write_to=os.path.join(ICONS, f"{app_id}.png"), output_width=256, output_height=256)
print("icons:", len(APPS))

# ----------------------------------------------------------- ui textures ----
def make_rounded(path, sz, radius):
    img = Image.new("RGBA", (sz, sz), (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle([0, 0, sz - 1, sz - 1], radius=radius, fill=(255, 255, 255, 255))
    img.save(path)

make_rounded(os.path.join(UI, "rounded.png"), 64, 16)
img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
ImageDraw.Draw(img).ellipse([0, 0, 63, 63], fill=(255, 255, 255, 255))
img.save(os.path.join(UI, "circle.png"))

# ----------------------------------------------------------------- sounds ----
SR = 22050
def env(t, dur, att=0.01, rel=0.04):
    e = 1.0
    if t < att: e = t / att
    elif t > dur - rel: e = max(0.0, (dur - t) / rel)
    return max(0.0, e)

def tone(freq, dur, amp=0.5, t0=0.0):
    n = int(SR * (t0 + dur))
    buf = [0.0] * n
    for i in range(int(SR * t0), n):
        buf[i] = amp * math.sin(2 * math.pi * freq * (i / SR - t0)) * env(i / SR - t0, dur)
    return buf

def mix_into(buf, sig):
    for i, v in enumerate(sig):
        buf[i] += v

def sweep(f1, f2, dur, amp=0.45):
    n = int(SR * dur)
    out = []
    ph = 0.0
    for i in range(n):
        f = f1 + (f2 - f1) * (i / n)
        ph += 2 * math.pi * f / SR
        out.append(amp * math.sin(ph) * env(i / SR, dur, 0.004, 0.03))
    return out

def save_wav(path, data):
    data = [max(-0.98, min(0.98, d)) for d in data]
    with wave.open(path, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(d * 32767)) for d in data))

# ring: chime pattern
def ring():
    pat = [(1318.5, .16), (1567.98, .16), (None, .10), (1318.5, .16), (1567.98, .16), (None, .5),
           (1318.5, .16), (1567.98, .16), (None, .10), (1318.5, .16), (1567.98, .16), (None, 1.05)]
    buf = []
    t = 0.0
    for f, d in pat:
        if f:
            n = int(SR * d)
            for i in range(n):
                tt = i / SR
                buf.append(0.5 * math.sin(2 * math.pi * f * tt) * env(tt, d, 0.012, 0.05))
        t += d
    return buf

save_wav(os.path.join(SOUNDS, "ring.wav"), ring())
b = [0.0] * int(SR * 0.6); mix_into(b, tone(880, 0.13, 0.4, 0.0)); mix_into(b, tone(1174.66, 0.2, 0.4, 0.15))
save_wav(os.path.join(SOUNDS, "notify.wav"), b)
save_wav(os.path.join(SOUNDS, "send.wav"), sweep(480, 940, 0.09, 0.4))
save_wav(os.path.join(SOUNDS, "click.wav"), tone(1700, 0.03, 0.3))
save_wav(os.path.join(SOUNDS, "back.wav"), sweep(620, 380, 0.05, 0.3))
print("sounds ok")

# ---------------------------------------------------------- contact sheet ----
sheet = Image.new("RGBA", (4 * 288 + 48, 4 * 288 + 48), (16, 18, 24, 255))
for i, (app_id, *_r) in enumerate(APPS):
    ic = Image.open(os.path.join(ICONS, f"{app_id}.png")).convert("RGBA").resize((256, 256))
    sheet.paste(ic, (48 + (i % 4) * 288, 48 + (i // 4) * 288), ic)
sheet.save(os.path.join(PREVIEW, "icons_contact_sheet.png"))
print("sheet ok")
