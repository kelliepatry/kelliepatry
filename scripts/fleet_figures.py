"""Builds the header and figures for the fleet article as SVG, then PNG via rsvg-convert.
Monotone style: black, greys, white ground. Inter."""
import subprocess, pathlib

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
    subprocess.run(["rsvg-convert", "-z", "1", "-o", str(OUT / f"{name}.png"), str(p)], check=True)


# ---------- Header: one model trying to do everything vs a wired fleet ----------
W, H = 1600, 680
b = [t(80, 90, "BUILD THE FLEET", 20, 600, MID, ls=4),
     t(80, 140, "One model powering through, or many small workers wired to one record.", 30, 500)]
# left: one big circle tangled
cx, cy = 400, 400
b.append(f'<circle cx="{cx}" cy="{cy}" r="120" fill="none" stroke="{INK}" stroke-width="3"/>')
b.append(t(cx, cy + 8, "MODEL", 22, 600, anchor="middle", ls=3))
import math, random
random.seed(7)
for i in range(16):
    a1 = random.uniform(0, 2 * math.pi); r2 = random.uniform(140, 175); a2 = a1 + random.uniform(-0.9, 0.9)
    x1, y1 = cx + 120 * math.cos(a1), cy + 120 * math.sin(a1)
    x2, y2 = cx + r2 * math.cos(a2), cy + r2 * math.sin(a2)
    b.append(f'<path d="M{x1:.0f},{y1:.0f} Q{cx + 215*math.cos(a1+0.5):.0f},{cy + 215*math.sin(a1+0.5):.0f} {x2:.0f},{y2:.0f}" fill="none" stroke="{RULE}" stroke-width="2"/>')
b.append(t(cx, 630, "asks, guesses, searches, counts, reasons — all at once", 18, 400, MID, anchor="middle"))
# divider
b.append(line(800, 200, 800, 600, RULE, 1, False))
# right: record bar, workers row, model above
rx = 900
b.append(box(rx, 470, 620, 60, "#111111", INK))
b.append(t(rx + 310, 508, "ONE RECORD", 20, 600, "#ffffff", anchor="middle", ls=3))
for i in range(8):
    x = rx + 20 + i * 76
    b.append(box(x, 360, 52, 52, "#ffffff", INK, 2))
    b.append(line(x + 26, 412, x + 26, 466, INK, 1.5, False))
b.append(t(rx + 310, 345, "workers: find · count · list · match · extract · check", 17, 400, MID, anchor="middle"))
b.append(box(rx + 210, 200, 200, 70, "#ffffff", INK, 3))
b.append(t(rx + 310, 243, "MODEL", 22, 600, anchor="middle", ls=3))
b.append(line(rx + 310, 318, rx + 310, 276, INK, 2))
b.append(t(rx + 330, 305, "packet", 16, 500, MID))
b.append(t(rx + 310, 630, "reasons from a packet the fleet assembled", 18, 400, MID, anchor="middle"))
render("fleet-header", svg(W, H, "".join(b)))

# ---------- Fig 1: What GitHub does, for a novice ----------
W, H = 1600, 760
b = [t(80, 80, "FIG. 1", 18, 600, MID, ls=4),
     t(80, 125, "What GitHub does, in five words: keep, try, propose, review, run.", 30, 500)]
# main line
y = 330
b.append(line(120, y, 1480, y, INK, 4, False))
b.append(t(120, y - 24, "main — the version everyone trusts", 18, 600))
# branch
b.append(f'<path d="M360,{y} C430,{y} 430,{y+170} 520,{y+170} L980,{y+170} C1080,{y+170} 1080,{y} 1160,{y}" fill="none" stroke="{MID}" stroke-width="3"/>')
b.append(t(560, y + 210, "branch — a safe copy to try something", 18, 500, MID))
for i, x in enumerate([600, 720, 840]):
    b.append(f'<circle cx="{x}" cy="{y+170}" r="13" fill="#ffffff" stroke="{INK}" stroke-width="3"/>')
b.append(t(600, y + 140, "commits — saved changes, each with a note", 17, 400, MID))
b.append(box(900, y + 40, 150, 50, "#ffffff", INK, 2, "6 4"))
b.append(t(975, y + 72, "pull request", 17, 600, anchor="middle"))
b.append(f'<circle cx="1160" cy="{y}" r="16" fill="{INK}"/>')
b.append(t(1160, y - 30, "merge", 18, 600, anchor="middle"))
for x in [200, 300, 1300, 1420]:
    b.append(f'<circle cx="{x}" cy="{y}" r="11" fill="#ffffff" stroke="{INK}" stroke-width="3"/>')
# actions
b.append(box(1240, y + 130, 240, 90, LIGHT, INK, 2))
b.append(t(1360, y + 168, "Actions", 20, 600, anchor="middle"))
b.append(t(1360, y + 196, "robots that run on a trigger", 15, 400, MID, anchor="middle"))
b.append(line(1360, y + 126, 1360, y + 22, INK, 2))
# legend row
labels = [("KEEP", "a repository is a folder that remembers"), ("TRY", "a branch lets you break things privately"),
          ("PROPOSE", "a pull request asks to change main"), ("REVIEW", "someone reads the difference first"),
          ("RUN", "Actions do work when something happens")]
for i, (k, v) in enumerate(labels):
    x = 80 + i * 300
    b.append(t(x, 690, k, 16, 700, ls=3))
    b.append(t(x, 716, v, 15, 400, MID))
render("fleet-fig-1", svg(W, H, "".join(b)))

# ---------- Fig 2: power through vs packet ----------
W, H = 1600, 700
b = [t(80, 80, "FIG. 2", 18, 600, MID, ls=4),
     t(80, 125, "Powering through versus working from a packet.", 30, 500)]
# left
b.append(t(80, 200, "POWER THROUGH", 18, 700, ls=3))
b.append(box(80, 230, 620, 380, "#ffffff", RULE, 2))
b.append(box(300, 260, 180, 60, "#ffffff", INK, 3))
b.append(t(390, 298, "model", 20, 600, anchor="middle"))
srcs = ["code", "record", "notes", "mail", "files"]
for i, s in enumerate(srcs):
    x = 110 + i * 116
    b.append(box(x, 520, 96, 54, "#ffffff", INK, 2))
    b.append(t(x + 48, 553, s, 16, 500, anchor="middle"))
    b.append(line(390, 322, x + 48, 516, MID, 1.5, True, "5 4", grey=True))
    b.append(line(x + 48, 516, 390, 324, RULE, 1, False))
b.append(t(390, 640, "every turn rediscovers the business: costly, unrepeatable, feels fast", 16, 500, MID, anchor="middle"))
# right
b.append(t(880, 200, "BUILD THE FLEET", 18, 700, ls=3))
b.append(box(880, 230, 640, 380, "#ffffff", RULE, 2))
b.append(box(1110, 260, 180, 60, "#ffffff", INK, 3))
b.append(t(1200, 298, "model", 20, 600, anchor="middle"))
b.append(box(1050, 360, 300, 50, LIGHT, INK, 2))
b.append(t(1200, 392, "research packet", 17, 600, anchor="middle"))
b.append(line(1200, 356, 1200, 324, INK, 2))
for i in range(5):
    x = 920 + i * 116
    b.append(box(x + 24, 450, 48, 40, "#ffffff", INK, 2))
    b.append(line(x + 48, 446, 1200, 414, MID, 1.2, False))
    b.append(box(x, 520, 96, 54, "#ffffff", INK, 2))
    b.append(t(x + 48, 553, srcs[i], 16, 500, anchor="middle"))
    b.append(line(x + 48, 516, x + 48, 494, INK, 1.5, False))
b.append(t(1200, 640, "workers do the finding; the model does the judging", 16, 500, MID, anchor="middle"))
render("fleet-fig-2", svg(W, H, "".join(b)))

# ---------- Fig 3: wiring ----------
W, H = 1600, 760
b = [t(80, 80, "FIG. 3", 18, 600, MID, ls=4),
     t(80, 125, "Four places, one change. If a change lands in one and the others can't read it, it didn't happen.", 26, 500)]
cx, cy = 800, 440
b.append(f'<circle cx="{cx}" cy="{cy}" r="95" fill="{INK}"/>')
b.append(t(cx, cy - 4, "THE CHANGE", 17, 700, "#ffffff", anchor="middle", ls=2))
b.append(t(cx, cy + 22, "one intention", 15, 400, "#dddddd", anchor="middle"))
nodes = [("CODE", "repository: how things run", 300, 260), ("RECORD", "database: what is true", 1300, 260),
         ("NOTES", "workspace: what people read", 300, 620), ("SKILLS", "instructions: how models behave", 1300, 620)]
for k, v, x, y in nodes:
    b.append(box(x - 170, y - 55, 340, 110, "#ffffff", INK, 2))
    b.append(t(x, y - 8, k, 20, 700, anchor="middle", ls=3))
    b.append(t(x, y + 22, v, 15, 400, MID, anchor="middle"))
    dx, dy = x - cx, y - cy; d = math.hypot(dx, dy)
    b.append(line(cx + dx / d * 100, cy + dy / d * 100, x - dx / d * 190, y - dy / d * 75, INK, 2))
# ring links between nodes
b.append(line(475, 260, 1125, 260, RULE, 2, False, "8 6"))
b.append(line(475, 620, 1125, 620, RULE, 2, False, "8 6"))
b.append(line(300, 320, 300, 560, RULE, 2, False, "8 6"))
b.append(line(1300, 320, 1300, 560, RULE, 2, False, "8 6"))
b.append(t(800, 250, "the fleet keeps these in step", 15, 500, MID, anchor="middle"))
b.append(t(800, 720, "dashed = maintenance the workers own, not the model and not you", 15, 400, MID, anchor="middle"))
render("fleet-fig-3", svg(W, H, "".join(b)))
print("done", sorted(p.name for p in OUT.iterdir()))

# ---------- Fig 4: single-line diagram, translated ----------
W, H = 1600, 840
b = [t(80, 80, "FIG. 4", 18, 600, MID, ls=4),
     t(80, 125, "A single-line diagram of an AI system, labeled in both trades.", 30, 500)]
def node(x, y, w, h, trade, ai, fill="#ffffff", txt=INK, sub=MID):
    b.append(box(x, y, w, h, fill, INK, 2))
    b.append(t(x + w/2, y + h/2 - 4, trade, 18, 700, txt, anchor="middle", ls=2))
    b.append(t(x + w/2, y + h/2 + 22, ai, 15, 400, sub, anchor="middle"))
node(80, 380, 230, 90, "UTILITY", "your data sources")
b.append(line(310, 425, 388, 425, INK, 3))
node(390, 350, 250, 150, "MAIN PANEL", "orchestrator", INK, "#ffffff", "#dddddd")
b.append(t(515, 335, "panel schedule = worker registry", 15, 400, MID, anchor="middle"))
# breakers + circuits
rows = [(200, "CIRCUIT 1", "workflow"), (405, "CIRCUIT 2", "workflow"), (610, "CIRCUIT 3", "workflow")]
for y, c, w_ in rows:
    b.append(line(640, 425, 700, y + 25, INK, 2, False))
    b.append(box(700, y, 70, 50, LIGHT, INK, 2))
    b.append(t(735, y + 31, "BKR", 14, 700, anchor="middle"))
    b.append(line(770, y + 25, 860, y + 25, INK, 2))
    b.append(t(815, y + 15, c, 13, 600, MID, anchor="middle"))
b.append(t(735, 185, "breaker = gate / stop condition", 15, 400, MID, anchor="middle"))
# loads
node(860, 195, 280, 60, "LOW VOLTAGE", "workers: cheap, plain, repeatable")
node(860, 400, 280, 60, "LINE VOLTAGE", "model: costly, used for judgment")
node(860, 605, 280, 60, "TIME CLOCK", "scheduled job / trigger")
for y in [225, 430, 635]:
    b.append(line(1140, y, 1218, y, INK, 2))
node(1220, 195, 280, 60, "FIXTURE", "the app you see")
node(1220, 400, 280, 60, "RECEPTACLE", "tool / API, standard plug")
node(1220, 605, 280, 60, "CONTACTOR", "trigger starts a larger run")
b.append(f'<rect x="80" y="725" width="1420" height="14" fill="{INK}"/>')
b.append(line(515, 500, 515, 723, INK, 2, False))
b.append(t(1500, 712, "GROUND BUS · one record everything references", 15, 700, anchor="end", ls=2))
b.append(t(80, 790, "Read left to right like a riser: power in, protection, distribution, use. Every box should appear on the panel schedule.", 16, 400, MID))
render("fleet-fig-4", svg(W, H, "".join(b)))
