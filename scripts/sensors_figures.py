"""Header and figures for "Sensors, not time clocks" as SVG, then PNG via rsvg-convert.
Monotone style: black, greys, white ground. Inter. Same helpers as fleet_figures.py."""
import subprocess, pathlib, shutil

OUT = pathlib.Path(__file__).resolve().parent.parent / "assets"
OUT.mkdir(exist_ok=True)
INK, MID, LIGHT, RULE = "#111111", "#6b6b6b", "#d9d9d9", "#bdbdbd"
FONT = "Inter, Helvetica, Arial, sans-serif"


def svg(w, h, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
            f'<rect width="{w}" height="{h}" fill="#ffffff"/>'
            f'<defs><marker id="a" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
            f'<path d="M0,0 L10,5 L0,10 z" fill="{INK}"/></marker>'
            f'<marker id="g" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
            f'<path d="M0,0 L10,5 L0,10 z" fill="{MID}"/></marker></defs>'
            f'{body}</svg>')


def t(x, y, s, size=22, w=400, fill=INK, anchor="start", ls=0):
    return (f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{size}" font-weight="{w}" '
            f'fill="{fill}" text-anchor="{anchor}" letter-spacing="{ls}">{s}</text>')


def box(x, y, w, h, fill="#ffffff", stroke=INK, sw=2, dash=None):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{d}/>'


def line(x1, y1, x2, y2, stroke=INK, sw=2, arrow=True, dash=None, grey=False):
    m = (' marker-end="url(#g)"' if grey else ' marker-end="url(#a)"') if arrow else ""
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{stroke}" stroke-width="{sw}"{m}{d}/>'


def render(name, content):
    p = OUT / f"{name}.svg"
    p.write_text(content)
    if shutil.which("rsvg-convert"):
        subprocess.run(["rsvg-convert", "-z", "1", "-o", str(OUT / f"{name}.png"), str(p)], check=True)


# ---------- Header: time clock / sensor ----------
b = []
b.append(t(80, 90, "TIME CLOCK", 26, 700, ls=4))
b.append(t(880, 90, "SENSOR", 26, 700, ls=4))
b.append(t(80, 124, "every room on at its hour, work or not", 18, 400, MID))
b.append(t(880, 124, "dark until something changes", 18, 400, MID))
b.append(line(800, 60, 800, 640, RULE, 2, arrow=False))
# left: clock + six lit rooms
b.append(f'<circle cx="390" cy="230" r="54" fill="#ffffff" stroke="{INK}" stroke-width="3"/>')
b.append(line(390, 230, 390, 192, INK, 4, arrow=False))
b.append(line(390, 230, 420, 246, INK, 4, arrow=False))
for i in range(6):
    x = 110 + (i % 3) * 200
    y = 340 + (i // 3) * 140
    b.append(box(x, y, 160, 100, "#111111", INK, 2))
    b.append(t(x + 80, y + 58, "on", 18, 600, "#ffffff", anchor="middle", ls=2))
    if y == 340:
        b.append(line(390, 284, x + 80, y - 6, MID, 1.5, grey=True))
b.append(t(390, 660, "six runs · one had work", 18, 400, MID, anchor="middle"))
# right: six dark rooms, one lit, one signal
for i in range(6):
    x = 910 + (i % 3) * 200
    y = 340 + (i // 3) * 140
    lit = i == 4
    b.append(box(x, y, 160, 100, "#111111" if lit else "#ffffff", INK, 2 if lit else 1.5, None if lit else "6 4"))
    b.append(t(x + 80, y + 58, "on" if lit else "off", 18, 600, "#ffffff" if lit else MID, anchor="middle", ls=2))
    b.append(f'<circle cx="{x + 146}" cy="{y + 14}" r="6" fill="{INK if lit else "#ffffff"}" stroke="{INK}" stroke-width="2"/>')
b.append(box(1110, 190, 180, 70, "#ffffff", INK, 3))
b.append(t(1200, 233, "PANEL", 18, 700, anchor="middle", ls=3))
b.append(line(1256, 474, 1220, 266, INK, 3))
b.append(t(1205, 300, "one signal", 18, 600, anchor="end"))
b.append(t(1190, 660, "one run · one had work", 18, 400, MID, anchor="middle"))
render("sensors-header", svg(1600, 700, "".join(b)))

# ---------- Fig 1: two keys ----------
b = []
states = [("BUILT", "builder makes it"), ("CHECKED", "a different checker passes it"),
          ("READY", "for the owner"), ("RELEASED", "owner lets it go live")]
xs = [80, 460, 840, 1220]
for (name, sub), x in zip(states, xs):
    last = name == "RELEASED"
    b.append(box(x, 150, 300, 110, "#111111" if last else "#ffffff", INK, 3))
    b.append(t(x + 150, 205, name, 24, 700, "#ffffff" if last else INK, anchor="middle", ls=3))
    b.append(t(x + 150, 238, sub, 16, 400, "#dddddd" if last else MID, anchor="middle"))
for x in xs[:-1]:
    b.append(line(x + 304, 205, x + 376, 205, INK, 3))
b.append(t(80, 90, "TWO KEYS BEFORE ANYTHING GOES LIVE", 22, 700, ls=3))
b.append(t(80, 120, "the builder never grades its own work", 18, 400, MID))
# fail loop
b.append(f'<path d="M610,262 L610,380 L230,380 L230,266" fill="none" stroke="{MID}" stroke-width="2" stroke-dasharray="7 5" marker-end="url(#g)"/>')
b.append(box(300, 352, 240, 56, "#ffffff", MID, 2, "6 4"))
b.append(t(420, 386, "fail → new builder", 17, 600, MID, anchor="middle"))
b.append(t(625, 300, "first key: checker", 17, 400, MID))
b.append(t(1370, 330, "second key: owner", 17, 400, MID, anchor="middle"))
b.append(line(610, 300, 610, 300, arrow=False))
render("sensors-fig-1", svg(1600, 460, "".join(b)))

# ---------- Fig 2: pull vs push ----------
b = []
b.append(t(80, 80, "PULL ON A SCHEDULE", 22, 700, ls=3))
b.append(t(880, 80, "PUSH ON A CHANGE", 22, 700, ls=3))
b.append(line(800, 50, 800, 650, RULE, 2, arrow=False))
srcs = ["mail", "meetings", "record", "files"]
# left
for i, s in enumerate(srcs):
    x = 100 + i * 165
    b.append(box(x, 470, 140, 60, "#ffffff", INK, 2))
    b.append(t(x + 70, 507, s, 17, 600, anchor="middle"))
for j, (r, hh) in enumerate([("role A", "06:00"), ("role B", "Tue · Fri")]):
    x = 170 + j * 330
    b.append(box(x, 170, 200, 70, "#ffffff", INK, 3))
    b.append(t(x + 100, 203, r, 18, 700, anchor="middle"))
    b.append(t(x + 100, 226, "wakes " + hh, 15, 400, MID, anchor="middle"))
    for i in range(4):
        b.append(line(x + 100, 244, 170 + i * 165, 464, MID, 1.5, grey=True))
b.append(t(440, 600, "every role reads every source to learn if anything changed", 16, 400, MID, anchor="middle"))
# right
for i, s in enumerate(srcs):
    x = 900 + i * 165
    b.append(box(x, 470, 140, 60, "#ffffff", INK, 2))
    b.append(t(x + 70, 507, s, 17, 600, anchor="middle"))
    b.append(f'<circle cx="{x + 70}" cy="420" r="14" fill="{INK if i == 0 else "#ffffff"}" stroke="{INK}" stroke-width="3"/>')
    b.append(line(x + 70, 466, x + 70, 438, INK, 2, arrow=False))
b.append(t(1240, 392, "watchers (workers)", 15, 400, MID, anchor="middle"))
b.append(box(900, 170, 300, 70, "#ffffff", INK, 3))
b.append(t(1050, 203, "role that owns mail", 18, 700, anchor="middle"))
b.append(t(1050, 226, "decides what to do", 15, 400, MID, anchor="middle"))
b.append(line(970, 404, 1020, 246, INK, 3))
b.append(t(1000, 330, "signal", 16, 600))
b.append(box(1290, 170, 220, 70, "#ffffff", MID, 2, "6 4"))
b.append(t(1400, 211, "heartbeat · once a day", 15, 400, MID, anchor="middle"))
b.append(t(1240, 600, "watchers read; one signal goes to the role that owns it", 16, 400, MID, anchor="middle"))
render("sensors-fig-2", svg(1600, 660, "".join(b)))
print("ok")
