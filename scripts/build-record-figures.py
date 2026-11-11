"""Technical figures for 'From model maps to a working record'.

Schematic only: no live records, no measured data. Geometry is orthogonal and
on a 10 px grid; spacing has no quantitative meaning.
Colour carries meaning and nothing else: warm = a person's authority,
cool = the durable record, ink and greys = everything else.

Rebuild from the repository root:
    python3 scripts/build-record-figures.py          # writes SVG masters
    node scripts/rasterize-figures.cjs               # writes PNGs (Playwright)
"""
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / 'assets' / 'record'
OUT.mkdir(parents=True, exist_ok=True)

W, H = 1600, 820
BG, INK, MID, FAINT, GRID = '#F4F4F2', '#161615', '#7C7C79', '#C6C6C3', '#DCDCD8'
WARM, COOL = '#C8692E', '#2E8EA3'
FONT = "DejaVu Sans Mono, Menlo, Consolas, monospace"


def esc(s):
    return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def text(x, y, s, size=15, fill=INK, anchor='start', ls=1, weight='normal'):
    return (f'<text x="{x}" y="{y}" font-size="{size}" fill="{fill}" text-anchor="{anchor}" '
            f'letter-spacing="{ls}" font-weight="{weight}">{esc(s)}</text>')


def line(x1, y1, x2, y2, stroke=INK, w=1.6, dash=None):
    d = f' stroke-dasharray="{dash}"' if dash else ''
    return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{stroke}" stroke-width="{w}"{d}/>'


def rect(x, y, w, h, stroke=INK, fill='none', sw=1.6, dash=None):
    d = f' stroke-dasharray="{dash}"' if dash else ''
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{d}/>'


def arrow_r(x, y, stroke=INK, w=1.6):
    """Open arrowhead pointing right with its tip at (x, y)."""
    return f'<path d="M{x-10} {y-6} L{x} {y} L{x-10} {y+6}" fill="none" stroke="{stroke}" stroke-width="{w}"/>'


def callout(x, y, n):
    return (f'<circle cx="{x}" cy="{y}" r="12" fill="{BG}" stroke="{INK}" stroke-width="1.2"/>'
            + text(x, y + 5, str(n), 13, INK, 'middle', 0))


def marker(x, y, color=COOL, s=12):
    return f'<rect x="{x-s/2}" y="{y-s/2}" width="{s}" height="{s}" fill="{color}"/>'


def page(n, title, body, source):
    defs = (
        '<defs>'
        f'<pattern id="dots" width="40" height="40" patternUnits="userSpaceOnUse"><circle cx="20" cy="20" r="1" fill="{GRID}"/></pattern>'
        f'<pattern id="hatch" width="9" height="9" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">'
        f'<line x1="0" y1="0" x2="0" y2="9" stroke="{INK}" stroke-width="1"/></pattern>'
        f'<pattern id="hatchfaint" width="9" height="9" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">'
        f'<line x1="0" y1="0" x2="0" y2="9" stroke="{FAINT}" stroke-width="1"/></pattern>'
        '</defs>'
    )
    head = (text(60, 78, f'FIG. {n}', 26, MID, ls=3)
            + text(190, 78, title, 26, INK, ls=1))
    foot = (line(60, 740, 1540, 740, FAINT, 1)
            + text(60, 780, source, 16, MID, ls=0)
            + f'<text x="1540" y="780" font-size="16" fill="{MID}" text-anchor="end" letter-spacing="1">'
              f'<tspan fill="{WARM}">ROOM</tspan> / <tspan fill="{COOL}">RECORD</tspan>  KP × CLAUDE</text>')
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" font-family="{FONT}">'
            f'{defs}<rect width="{W}" height="{H}" fill="{BG}"/><rect width="{W}" height="{H}" fill="url(#dots)"/>'
            f'{head}{body}{foot}</svg>\n')


# ---------------------------------------------------------------- FIG. 1
def fig1():
    b = []
    # instrumented boundary and sealed model
    b.append(rect(560, 220, 480, 340, MID, sw=1.2, dash='6 5'))
    b.append(text(560, 206, 'INSTRUMENTED BOUNDARY', 13, MID, ls=2))
    b.append(rect(660, 290, 280, 200, INK, 'url(#hatch)', 2))
    b.append(rect(720, 365, 160, 50, INK, BG, 1.2))
    b.append(text(800, 397, 'MODEL', 18, INK, 'middle', 4))
    # inputs
    for y, label in [(340, 'SOURCES + REVISIONS'), (440, 'QUESTION + VERSION')]:
        b.append(line(300, y, 658, y))
        b.append(arrow_r(658, y))
        b.append(text(280, y + 5, label, 14, INK, 'end', 1))
    # model identity leader
    b.append(line(800, 290, 800, 220, INK, 1.2))
    # output chain
    b.append(line(940, 390, 1148, 390)); b.append(arrow_r(1148, 390))
    b.append(rect(1150, 355, 100, 70))
    b.append(text(1200, 396, 'RULE', 15, INK, 'middle', 2))
    b.append(line(1250, 390, 1302, 390)); b.append(arrow_r(1302, 390))
    b.append(f'<circle cx="1340" cy="390" r="36" fill="none" stroke="{WARM}" stroke-width="2.4"/>')
    b.append(text(1340, 396, 'SIGN', 15, WARM, 'middle', 2))
    b.append(line(1376, 390, 1428, 390)); b.append(arrow_r(1428, 390))
    b.append(rect(1430, 355, 100, 70, COOL, sw=2.4))
    b.append(text(1480, 396, 'RECORD', 15, COOL, 'middle', 2))
    # logged crossings
    for x, y in [(560, 340), (560, 440), (800, 220), (1040, 390)]:
        b.append(marker(x, y))
    for x, y, n in [(532, 316, 1), (532, 464, 2), (828, 220, 3), (1068, 364, 4),
                    (1200, 330, 5), (1340, 330, 6), (1480, 330, 7)]:
        b.append(callout(x, y, n))
    b.append(text(800, 600, 'inside: not inspectable   ·   at the edge: logged', 15, MID, 'middle', 1))
    # key
    key = [('SOURCES', '+ revisions'), ('QUESTION', '+ version'), ('MODEL', '+ provider'),
           ('ANSWER', 'typed, or failed'), ('RULE', 'that acted'), ('SIGN-OFF', 'by a person'),
           ('RECORD', 'read back, received')]
    for i, (a, s) in enumerate(key):
        x = 72 + i * 212
        b.append(callout(x, 660, i + 1))
        colour = WARM if i == 5 else COOL if i == 6 else INK
        b.append(text(x + 22, 665, a, 14, colour, ls=1))
        b.append(text(x + 22, 687, s, 13, MID, ls=0))
    return page(1, 'The model is sealed. Its edges are not.', ''.join(b),
                'After Laabs [7] and Anthropic [2]. Schematic; no live system data.')


# ---------------------------------------------------------------- FIG. 2
def fig2():
    b = []
    panels = [(60, 'A', 'ATTRIBUTION GRAPH', 'inside one model · research'),
              (570, 'B', 'EVIDENCE GRAPH', 'sources and claims · your practice'),
              (1080, 'C', 'WORK RECORD', 'where the work stands · your practice')]
    for i, (x, letter, name, sub) in enumerate(panels):
        c = FAINT if i == 0 else INK
        b.append(rect(x, 120, 460, 560, c, sw=1.2, dash='6 5' if i == 0 else None))
        b.append(text(x + 24, 158, f'{letter}  {name}', 16, MID if i == 0 else INK, ls=2))
        b.append(text(x + 24, 182, sub, 13, MID, ls=0))
        b.append(line(x, 200, x + 460, 200, c, 1))

    # A: faint, dense, not ours
    import math
    pts = []
    for r in range(4):
        for k in range(5):
            pts.append((110 + k * 90 + (r % 2) * 40, 250 + r * 80))
    for (x1, y1) in pts:
        for (x2, y2) in pts:
            if (x1, y1) < (x2, y2) and math.dist((x1, y1), (x2, y2)) < 125:
                b.append(line(x1, y1, x2, y2, FAINT, 1))
    for (x, y) in pts:
        b.append(f'<circle cx="{x}" cy="{y}" r="5" fill="{BG}" stroke="{FAINT}" stroke-width="1.4"/>')
    b.append(text(84, 610, 'Bounded hypotheses about', 14, MID, ls=0))
    b.append(text(84, 632, 'one model. Not your map.', 14, MID, ls=0))

    # B: typed edges, missing evidence drawn
    S = {'S1': (640, 260), 'S2': (640, 360), 'S3': (640, 460)}
    C = {'C1': (830, 300), 'C2': (830, 440)}
    D = (950, 370)
    M = (950, 510)
    b.append(line(652, 260, 818, 300))                       # source-backed
    b.append(line(652, 360, 818, 300, INK, 1.6, '9 6'))      # calculated
    b.append(line(652, 460, 818, 440))                       # source-backed
    b.append(line(842, 300, 936, 370, INK, 1.6, '2 6'))      # proposed
    b.append(line(842, 440, 936, 370))
    b.append(line(842, 440, 938, 510, MID, 1.2, '2 6'))
    for k, (x, y) in S.items():
        b.append(rect(x - 12, y - 12, 24, 24, INK, BG, 1.6))
        b.append(text(x - 22, y + 5, k, 13, MID, 'end', 0))
    for k, (x, y) in C.items():
        b.append(f'<circle cx="{x}" cy="{y}" r="12" fill="{BG}" stroke="{INK}" stroke-width="1.6"/>')
        b.append(text(x, y - 22, k, 13, MID, 'middle', 0))
    b.append(f'<path d="M{D[0]} {D[1]-14} L{D[0]+14} {D[1]} L{D[0]} {D[1]+14} L{D[0]-14} {D[1]} Z" fill="{BG}" stroke="{INK}" stroke-width="1.6"/>')
    b.append(text(D[0] - 22, D[1] - 26, 'CONCLUSION', 12, INK, 'start', 0))
    b.append(rect(M[0] - 12, M[1] - 12, 24, 24, MID, 'none', 1.4, '4 3'))
    b.append(text(M[0], M[1] + 36, 'MISSING', 13, MID, 'middle', 1))
    # legend: line types
    ly = 575
    for j, (dash, label) in enumerate([(None, 'source-backed'), ('9 6', 'calculated'), ('2 6', 'proposed')]):
        y = ly + j * 24
        b.append(line(594, y, 654, y, INK, 1.6, dash))
        b.append(text(668, y + 5, label, 13, INK, ls=0))
    b.append(rect(820, ly - 9, 18, 18, MID, 'none', 1.4, '4 3'))
    b.append(text(850, ly + 5, 'missing: drawn,', 13, MID, ls=0))
    b.append(text(850, ly + 24, 'never omitted', 13, MID, ls=0))

    # C: work record as a check grid
    cols = [('ID', 1104), ('REV', 1184), ('SIGN', 1254), ('SAVE', 1324), ('READ', 1394), ('RECV', 1464)]
    for name, x in cols:
        b.append(text(x, 240, name, 13, MID, ls=1))
    b.append(line(1100, 256, 1516, 256, INK, 1))
    rows = [('D-01', 'R4', 'SSSS'), ('D-02', 'R2', 'SSS.'), ('D-03', 'R3', 'SS..'),
            ('D-04', 'R1', 'H...'), ('D-05', 'R1', '....')]
    for r, (rid, rev, st) in enumerate(rows):
        y = 300 + r * 56
        b.append(text(1104, y + 5, rid, 14, INK, ls=0))
        b.append(text(1184, y + 5, rev, 14, INK, ls=0))
        for k, ch in enumerate(st):
            cx = cols[k + 2][1] + 16
            if st[0] == 'H' and k > 0:
                continue
            if ch == 'S':
                if k == 0:
                    b.append(f'<circle cx="{cx}" cy="{y}" r="7" fill="{WARM}"/>')
                else:
                    b.append(marker(cx, y, COOL, 13))
            elif ch == 'H':
                b.append(rect(cx - 8, y - 8, 226, 16, MID, 'url(#hatchfaint)', 1))
                b.append(text(cx + 105, y + 5, 'HOLD', 12, INK, 'middle', 2))
            else:
                b.append(rect(cx - 6, y - 6, 12, 12, FAINT, 'none', 1.2))
        b.append(line(1100, y + 28, 1516, y + 28, FAINT, 1))
    b.append(text(1104, 610, 'Signed, saved, read back and', 14, MID, ls=0))
    b.append(text(1104, 632, 'received are separate checks.', 14, MID, ls=0))
    return page(2, 'Three maps. Only two are yours.', ''.join(b),
                'Model graphs after Anthropic [2]. Panels B and C are schematic; no client records.')


# ---------------------------------------------------------------- FIG. 3
def fig3():
    b = []
    names = ['FRAME', 'RETRIEVE', 'MAP', 'JUDGE', 'APPLY RULES', 'REVIEW', 'SAVE', 'HAND OFF', 'CLOSE']
    kinds = ['rule', 'rule', 'rule', 'model', 'rule', 'person', 'record', 'record', 'record']
    xs = [140 + i * 165 for i in range(9)]
    rail, hold = 300, 470
    b.append(line(xs[0], rail, xs[-1], rail, INK, 2))
    b.append(line(xs[0], hold, xs[-1], hold, MID, 1.2, '6 5'))
    for i, (x, n, k) in enumerate(zip(xs, names, kinds)):
        b.append(text(x, 224, f'{i+1:02d}', 13, MID, 'middle', 1))
        b.append(text(x, 252, n, 15, INK, 'middle', 1))
        b.append(line(x, rail + 18, x, hold - 6, FAINT, 1.2, '3 4'))
        b.append(line(x - 5, hold, x + 5, hold, MID, 1.2))
        if k == 'rule':
            b.append(rect(x - 11, rail - 11, 22, 22, INK, INK, 1.6))
        elif k == 'model':
            b.append(rect(x - 16, rail - 16, 32, 32, INK, 'url(#hatch)', 2))
        elif k == 'person':
            b.append(f'<circle cx="{x}" cy="{rail}" r="13" fill="{WARM}"/>')
        else:
            b.append(rect(x - 11, rail - 11, 22, 22, COOL, COOL, 1.6))
    b.append(text(xs[0], hold + 40, 'HOLD   reason + named owner', 15, MID, ls=1))
    b.append(text(xs[0], hold + 64, 'Any station can halt. Work resumes at the affected step only after the owner clears it and evidence and permission are checked again.', 13, MID, ls=0))
    # legend
    ly = 650
    b.append(rect(140 - 9, ly - 9, 18, 18, INK, INK)); b.append(text(162, ly + 5, 'rule (deterministic)', 14, INK, ls=0))
    b.append(rect(390 - 11, ly - 11, 22, 22, INK, 'url(#hatch)', 1.6)); b.append(text(414, ly + 5, 'model judgment', 14, INK, ls=0))
    b.append(f'<circle cx="610" cy="{ly}" r="10" fill="{WARM}"/>'); b.append(text(630, ly + 5, 'person', 14, WARM, ls=0))
    b.append(rect(740 - 9, ly - 9, 18, 18, COOL, COOL)); b.append(text(762, ly + 5, 'record', 14, COOL, ls=0))
    b.append(text(1460, ly + 8, '1 of 9 stations calls a model.', 20, INK, 'end', 0))
    return page(3, 'Nine stations, one model call.', ''.join(b),
                'Proposed sequence; stations show order, not installed automation.')


# ---------------------------------------------------------------- FIG. 4
def fig4():
    b = []
    cols = [('01', 'MODEL', ['its own explanation'], ['the mechanism', 'that produced', 'the answer']),
            ('02', 'JUDGMENT', ['a confident answer'], ['a decision by', 'someone', 'authorized']),
            ('03', 'MAP', ['a line, a central node'], ['a documented', 'relationship', 'with a source']),
            ('04', 'DELIVERY', ['a polished summary'], ['read back,', 'received,', 'hold cleared'])]
    top, plate_h, gap, ground = 220, 14, 96, 560
    sup_top = top + plate_h + gap
    # left margin labels
    b.append(text(60, top + 12, 'SURFACE', 14, INK, ls=2))
    b.append(text(60, top + 30, 'looks finished', 12, MID, ls=0))
    b.append(text(60, top + plate_h + gap / 2 + 8, 'JOINT', 14, WARM, ls=2))
    b.append(text(60, top + plate_h + gap / 2 + 26, 'keep it visible', 12, MID, ls=0))
    b.append(text(60, sup_top + 22, 'SUPPORT', 14, INK, ls=2))
    b.append(text(60, sup_top + 40, 'established', 12, MID, ls=0))
    b.append(text(60, sup_top + 56, 'separately', 12, MID, ls=0))
    for i, (num, name, surf, sup) in enumerate(cols):
        x, w = 270 + i * 320, 260
        b.append(text(x, 150, num, 13, MID, ls=1))
        b.append(text(x + 34, 150, name, 16, INK, ls=2))
        for j, s in enumerate(surf):
            b.append(text(x, top - 16 + j * 18, s, 14, MID, ls=0))
        b.append(rect(x, top, w, plate_h, INK, INK, 1))
        # joint: dimension line
        cx = x + w / 2
        b.append(line(cx, top + plate_h + 6, cx, sup_top - 6, WARM, 1.4))
        b.append(line(cx - 8, top + plate_h + 6, cx + 8, top + plate_h + 6, WARM, 1.4))
        b.append(line(cx - 8, sup_top - 6, cx + 8, sup_top - 6, WARM, 1.4))
        # support in section
        b.append(rect(x, sup_top, w, ground - sup_top, INK, 'url(#hatch)', 1.6))
        ph = 22 * len(sup) + 20
        py = sup_top + (ground - sup_top - ph) / 2
        b.append(rect(x + 30, py, w - 60, ph, INK, BG, 1))
        for j, s in enumerate(sup):
            b.append(text(cx, py + 26 + j * 22, s, 14, INK, 'middle', 0))
    # ground line with drafting ticks
    b.append(line(250, ground, 1510, ground, INK, 2))
    for gx in range(260, 1510, 20):
        b.append(line(gx, ground, gx - 10, ground + 10, MID, 1))
    b.append(text(270, 640, 'A render is not a construction set.', 22, INK, ls=0))
    b.append(text(270, 672, 'Keep the surface and its support visibly separate. Never let one stand in for the other.', 15, MID, ls=0))
    return page(4, 'One pattern, four scales.', ''.join(b),
                'Section view, schematic. Joint = where a person checks before the surface is accepted.')


for name, fn in [('fig-1-sealed-model', fig1), ('fig-2-three-maps', fig2),
                 ('fig-3-nine-stations', fig3), ('fig-4-one-pattern', fig4)]:
    (OUT / f'{name}.svg').write_text(fn(), encoding='utf-8')
print(f'Wrote 4 SVG masters to {OUT}')
