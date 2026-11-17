"""Body-at-the-fixture plates: ink section/plan linework meets photo collage.

Visual grammar studied from Alvar Aalto's washbasin section for the Paimio
Tuberculosis Sanatorium (c. 1929, ink, pencil and photo collage). Nothing here
traces or reproduces that sheet. The fixtures are KPHD hospitality fixtures.
The rules are written out in articles/body-at-the-fixture.md, Part II.

The grey "photo" shapes are stand-ins. They are meant to be swapped for real
photographs: a cut-out PNG with a transparent background, set into the
photo layer in place of the stand-in silhouette.

Rebuild from repository root:
    python scripts/build-body-plates.py           # SVG plates + flipbook frames
    node scripts/rasterize-body-plates.cjs         # PNG plates, frames, MP4, GIF
Output: assets/body/ (plates) and assets/body/frames/ (flipbook, not committed).
Options: --paper aalto  draws on a warm paper ground instead of studio stone.
"""
from pathlib import Path
import math
import random
import sys

OUT = Path(__file__).resolve().parents[1] / 'assets' / 'body'
FRAMES = OUT / 'frames'

# ---- grammar ---------------------------------------------------------------
W, H = 1080, 1350                 # Instagram portrait, 4:5
FX, FY, FW, FH = 90, 140, 900, 960  # the inked frame
WARM = '--paper' in sys.argv and 'aalto' in sys.argv
GROUND = '#E6DCCD' if WARM else '#F4F4F2'
INK = '#161615'                    # object line and frame
PENCIL = '#8E8E8A'                 # layout, extension, dimension, reach
TEXT = '#585856'
OBJ, FRAME_W, RAY, PEN = 2.4, 1.6, 0.9, 0.8   # stroke weights, px at 1080 wide
# Photo tones, neutral greys only. Read from the source sheet: the collage
# never reaches the paper's white and its darkest garment sits near black.
PH_LIGHT, PH_MID, PH_DARK, PH_BLACK = '#BDBDBB', '#8F8F8D', '#5E5E5C', '#222221'

# The body is the scale bar. Every plate states its scale in px per mm, and the
# cut-out body is sized from these figures at that scale, so the eye reads the
# fixture's size from the hand, the forearm, the shin. Rounded adult figures
# for drawing, not for specification: check against an anthropometric
# reference before a plate states a dimension.
BODY = {                       # mm
    'hand_length': 190, 'hand_breadth': 85,
    'forearm': 260,            # elbow to wrist
    'upper_arm': 330,          # shoulder to elbow
    'elbow_w': 75, 'wrist_w': 55, 'upper_arm_w': 100,
    'thigh': 600,              # hip to knee front, seated
    'shin': 480,               # knee to ankle
    'thigh_w': 150, 'knee_w': 105, 'ankle_w': 70, 'foot': 260,
    'shoulder_breadth': 440,
    'elbow_height_standing': 1050, 'shoulder_above_seat': 600,
}


def head(extra=''):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
<defs>
  <clipPath id="frame"><rect x="0" y="0" width="{FW}" height="{FH}"/></clipPath>
  <filter id="grain" x="0" y="0" width="100%" height="100%">
    <feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="2" seed="7" result="n"/>
    <feColorMatrix in="n" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0.22 0" result="g"/>
    <feComposite in="g" in2="SourceGraphic" operator="in" result="gi"/>
    <feMerge><feMergeNode in="SourceGraphic"/><feMergeNode in="gi"/></feMerge>
  </filter>
  <linearGradient id="skin" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="{PH_LIGHT}"/><stop offset=".55" stop-color="{PH_MID}"/><stop offset="1" stop-color="{PH_DARK}"/>
  </linearGradient>
  <linearGradient id="cloth" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#A3A3A1"/><stop offset="1" stop-color="#7A7A78"/>
  </linearGradient>
  {extra}
</defs>
<rect width="{W}" height="{H}" fill="{GROUND}"/>
'''


def L(x1, y1, x2, y2, c=INK, w=OBJ, extra=''):
    return f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{c}" stroke-width="{w}" stroke-linecap="round" {extra}/>'


def P(d, c=INK, w=OBJ, fill='none', extra=''):
    return f'<path d="{d}" stroke="{c}" stroke-width="{w}" fill="{fill}" stroke-linejoin="round" stroke-linecap="round" {extra}/>'


def frame_and_margin(n, caption):
    """The inked frame, pencil extension lines past its corners, pencil
    arrows along two sides, a caption lettered under the frame, and the sheet
    number in a circle. All in sheet coordinates."""
    s = [f'<rect x="{FX}" y="{FY}" width="{FW}" height="{FH}" fill="none" stroke="{INK}" stroke-width="{FRAME_W}"/>']
    for x in (FX, FX + FW):
        s.append(L(x, FY - 40, x, FY - 6, PENCIL, PEN))
        s.append(L(x, FY + FH + 6, x, FY + FH + 34, PENCIL, PEN))
    for y in (FY, FY + FH):
        s.append(L(FX - 40, y, FX - 6, y, PENCIL, PEN))
        s.append(L(FX + FW + 6, y, FX + FW + 40, y, PENCIL, PEN))
    # pencil dimension arrows, no figures: they mark extent, not a measurement
    ay = FY + FH + 22
    s.append(L(FX + 8, ay, FX + FW - 8, ay, PENCIL, PEN))
    s.append(P(f'M{FX+22},{ay-6} L{FX+8},{ay} L{FX+22},{ay+6}', PENCIL, PEN))
    s.append(P(f'M{FX+FW-22},{ay-6} L{FX+FW-8},{ay} L{FX+FW-22},{ay+6}', PENCIL, PEN))
    ax = FX - 24
    s.append(L(ax, FY + 8, ax, FY + FH - 8, PENCIL, PEN))
    s.append(P(f'M{ax-6},{FY+22} L{ax},{FY+8} L{ax+6},{FY+22}', PENCIL, PEN))
    s.append(P(f'M{ax-6},{FY+FH-22} L{ax},{FY+FH-8} L{ax+6},{FY+FH-22}', PENCIL, PEN))
    s.append(f'<text x="{FX+4}" y="{FY+FH+80}" font-family="Space Mono, monospace" font-size="22" letter-spacing="3.2" fill="{TEXT}">{caption}</text>')
    cx, cy = FX + FW - 22, FY + FH + 120
    s.append(f'<circle cx="{cx}" cy="{cy}" r="22" fill="none" stroke="{PENCIL}" stroke-width="1.1"/>')
    s.append(f'<text x="{cx}" y="{cy+7}" text-anchor="middle" font-family="Space Mono, monospace" font-size="19" fill="{TEXT}">{n:02d}</text>')
    return '\n'.join(s)


def limb(x1, y1, w1, x2, y2, w2, fill='url(#skin)', cap=True):
    """A tapered limb as one closed outline with a rounded far end: the
    stand-in for a photographed forearm, cut along its contour."""
    a = math.atan2(y2 - y1, x2 - x1)
    nx, ny = -math.sin(a), math.cos(a)
    p1 = (x1 + nx * w1 / 2, y1 + ny * w1 / 2)
    p2 = (x2 + nx * w2 / 2, y2 + ny * w2 / 2)
    p3 = (x2 - nx * w2 / 2, y2 - ny * w2 / 2)
    p4 = (x1 - nx * w1 / 2, y1 - ny * w1 / 2)
    r = w2 / 2
    end = f'A{r:.1f},{r:.1f} 0 0 0 {p3[0]:.1f},{p3[1]:.1f}' if cap else f'L{p3[0]:.1f},{p3[1]:.1f}'
    d = (f'M{p1[0]:.1f},{p1[1]:.1f} Q{(p1[0]+p2[0])/2 + nx*4:.1f},{(p1[1]+p2[1])/2 + ny*4:.1f} {p2[0]:.1f},{p2[1]:.1f} '
         f'{end} Q{(p3[0]+p4[0])/2 - nx*3:.1f},{(p3[1]+p4[1])/2 - ny*3:.1f} {p4[0]:.1f},{p4[1]:.1f} Z')
    return f'<path d="{d}" fill="{fill}" filter="url(#grain)"/>'


def hands(hx, hy, rot=12, s=1.0):
    # at s=1 the clasped pair is about 160 units long: s = hand_length * k / 160
    """Two hands clasped, seen from the side: a palm mass with four finger
    lobes at its leading edge. Stand-in for a cut-out photograph."""
    g = [f'<g transform="translate({hx:.1f},{hy:.1f}) rotate({rot}) scale({s})" filter="url(#grain)">']
    g.append(f'<ellipse cx="-6" cy="0" rx="64" ry="30" fill="url(#skin)"/>')
    for i, (dx, dy, rx) in enumerate([(52, -18, 26), (62, -5, 28), (60, 9, 26), (50, 22, 22)]):
        g.append(f'<ellipse cx="{dx}" cy="{dy}" rx="{rx}" ry="9" fill="{PH_MID if i % 2 else PH_LIGHT}"/>')
    g.append(f'<ellipse cx="-20" cy="24" rx="40" ry="14" fill="{PH_DARK}" opacity=".55"/>')  # shadowed lower hand
    g.append('</g>')
    return '\n'.join(g)


# ---- plate 01: hand sink, section -----------------------------------------
BACK_A, BACK_B = (760, 380), (560, 700)    # inner face of the inclined back


def back_y(x):
    (ax, ay), (bx, by) = BACK_A, BACK_B
    return ay + (x - ax) * (by - ay) / (bx - ax)


K1 = 1.2   # plate 01, px per mm. Rim at y 594; the floor is 865 mm below, out of frame.


def hand_sink(hx=580, hy=440, rot=12, jitter=0, seed=0, n=1, caption='HAND SINK · SECTION · WATER MEETS THE BACK AT A GLANCE'):
    rnd = random.Random(seed)
    j = lambda: rnd.uniform(-jitter, jitter)
    s = [head(), f'<g transform="translate({FX},{FY})">']
    # ground lines carry past the frame: wall and floor
    s.append(L(760, -60, 760, FH + 34, INK, FRAME_W))
    # no floor: at this scale it falls 1 m below the frame. A pencil break says so.
    s.append(P('M712,900 H752 L758,886 L768,914 L774,900 H812', PENCIL, PEN))
    # basin, one continuous double line: back, bottom, front, rolled bead, and back out to the wall
    s.append(P('M760,380 L560,700 C530,748 470,760 420,744 C360,724 320,680 300,630 L300,614 '
               'A12,12 0 1 0 286,616 L286,636 C300,690 350,742 415,759 C470,775 540,760 572.7,708 L760,408'))
    # waste: spigot through the foot, trap in pencil
    s.append(L(432, 748, 432, 800)); s.append(L(448, 750, 448, 800))
    s.append(P('M440,800 L440,840 Q440,856 456,856 L760,856', PENCIL, PEN))
    # supply: wall valve, arm, spout, drawn as a hollow pipe
    s.append(P('M760,250 H612 Q600,250 600,262 V292', INK, 15))
    s.append(P('M760,250 H612 Q600,250 600,262 V292', GROUND, 11))
    s.append(f'<rect x="750" y="232" width="10" height="36" fill="{GROUND}" stroke="{INK}" stroke-width="{FRAME_W}"/>')
    s.append(f'<circle cx="724" cy="250" r="14" fill="{GROUND}" stroke="{INK}" stroke-width="{FRAME_W}"/>')
    s.append(L(724, 236, 712, 196, INK, FRAME_W)); s.append(f'<circle cx="711" cy="192" r="5" fill="{INK}"/>')
    # water: four hairlines from the spout to the inclined back
    for i in range(4):
        x0 = 595 + i * 3.4
        x1 = x0 + (i - 1.5) * 2.2 + j()
        s.append(L(x0 + j() * .3, 294, x1, back_y(x1), INK, RAY))
    # the run-off: construction rays fanning down the back toward the waste
    ix, iy = 602, back_y(602)
    ux, uy = BACK_B[0] - BACK_A[0], BACK_B[1] - BACK_A[1]
    base = math.atan2(uy, ux)
    for k, da in enumerate((.03, .08, .14, .21)):   # fan into the bowl, never through the shell
        a = base + da
        ln = 118 - k * 12
        s.append(L(ix, iy, ix + math.cos(a) * ln + j(), iy + math.sin(a) * ln + j(), INK, RAY))
    # pencil: the angle the stream meets the back at
    s.append(P(f'M{ix},{iy-56} A56,56 0 0 1 {ix + 56*math.cos(base + math.pi):.1f},{iy + 56*math.sin(base + math.pi):.1f}', PENCIL, PEN))
    # photo layer: square-cut where it meets the frame, contour-cut where it enters the drawing
    s.append('<g clip-path="url(#frame)">')
    k, b = K1, BODY
    hs = b['hand_length'] * k / 160
    s.append(f'<rect x="0" y="60" width="190" height="372" fill="url(#cloth)" filter="url(#grain)"/>')
    s.append(f'<rect x="0" y="432" width="190" height="190" fill="{PH_BLACK}" filter="url(#grain)"/>')
    wx = hx - 70 * hs                      # wrist, at the heel of the clasped hands
    ex = wx - b['forearm'] * k * .96       # elbow, forearm slightly foreshortened
    s.append(limb(ex, 362, b['elbow_w'] * k, wx + 10, hy - 16, b['wrist_w'] * k))
    s.append(limb(ex + 10, 396, b['elbow_w'] * k, wx + 24, hy + 18, b['wrist_w'] * k, fill=f'{PH_MID}'))
    s.append(hands(hx, hy, rot, hs))
    s.append('</g></g>')
    s.append(frame_and_margin(n, caption))
    s.append('</svg>')
    return '\n'.join(s)


# ---- plate 02: bar rail, section ------------------------------------------
K2 = 2 / 3  # plate 02, px per mm. Floor y 900, bar top 1067 mm, stool seat 760 mm.


def bar_rail(n=2):
    s = [head(), f'<g transform="translate({FX},{FY})">']
    s.append(L(-60, 900, FW + 60, 900, INK, FRAME_W))
    # bar top with a bullnose to the guest, die, recessed toe kick
    s.append(P(f'M{FW},189 H406 A13.5,13.5 0 0 0 406,216 H560 V833 H610 V900'))
    s.append(L(560, 216, FW, 216, INK, FRAME_W))
    # under-bar shelf, hidden: pencil
    s.append(L(560, 520, FW, 520, PENCIL, PEN, 'stroke-dasharray="10 7"'))
    # foot rail: tube and bracket
    s.append(f'<circle cx="508" cy="747" r="17" fill="none" stroke="{INK}" stroke-width="{OBJ}"/>')
    s.append(f'<circle cx="508" cy="747" r="12" fill="none" stroke="{INK}" stroke-width="{RAY}"/>')
    s.append(P('M525,747 H560 M525,760 L545,760 L560,740', INK, FRAME_W))
    # a coupe on the top: line drawing the photographed hand reaches to
    s.append(P('M622,189 H658 M640,189 V140 M606,120 Q612,140 640,140 Q668,140 674,120 Z', INK, FRAME_W))
    # bar stool: seat at 760 mm, post, foot ring, base
    s.append(f'<rect x="20" y="393" width="260" height="20" fill="none" stroke="{INK}" stroke-width="{FRAME_W}"/>')
    s.append(L(150, 413, 150, 900, INK, FRAME_W)); s.append(L(90, 700, 210, 700, INK, FRAME_W))
    s.append(P('M60,900 Q150,876 240,900', INK, FRAME_W))
    # pencil: knee clearance under the overhang, reach arc from the shoulder
    s.append(L(393, 216, 393, 900, PENCIL, PEN, 'stroke-dasharray="4 6"'))
    s.append(P('M647,-156 A486,486 0 0 1 630,215', PENCIL, PEN, extra='clip-path="url(#frame)"'))
    # photo layer
    s.append('<g clip-path="url(#frame)">')
    k, b = K2, BODY
    # seated guest: shoulder 600 mm above the seat, square-cut into the top-left corner
    s.append(f'<rect x="0" y="0" width="230" height="330" fill="url(#cloth)" filter="url(#grain)"/>')
    s.append(f'<rect x="0" y="320" width="230" height="80" fill="{PH_BLACK}" filter="url(#grain)"/>')
    s.append(limb(120, 360, b['thigh_w'] * k, 120 + b['thigh'] * k, 375, b['knee_w'] * k, fill=PH_BLACK))   # knee under the overhang
    s.append(limb(512, 380, b['knee_w'] * k * .9, 492, 380 + b['shin'] * k * .99, b['ankle_w'] * k, fill=PH_BLACK))
    s.append(f'<path d="M455,700 Q500,698 540,722 Q560,734 556,742 L470,744 Q448,742 446,722 Z" fill="{PH_BLACK}" filter="url(#grain)"/>')
    s.append(limb(190, 10, b['upper_arm_w'] * k, 330, 172, b['elbow_w'] * k * 1.05, fill='url(#cloth)'))   # sleeve
    s.append(limb(330, 172, b['elbow_w'] * k, 330 + b['forearm'] * k, 172, b['wrist_w'] * k))           # forearm on the top
    s.append(f'<g filter="url(#grain)"><ellipse cx="{503 + b["hand_length"] * k / 2:.0f}" cy="170" rx="{b["hand_length"] * k / 2:.0f}" ry="15" fill="url(#skin)"/>'
             f'<ellipse cx="585" cy="160" rx="22" ry="7" fill="{PH_LIGHT}"/></g>')
    s.append('</g></g>')
    s.append(frame_and_margin(n, 'BAR RAIL · SECTION · FOREARM AND FOOT AT REST'))
    s.append('</svg>')
    return '\n'.join(s)


# ---- plate 03: two-top, plan ----------------------------------------------
K3 = 1.0    # plate 03, px per mm: table 600 x 600, plates 240, shoulders 440.


def two_top(n=3):
    s = [head(), f'<g transform="translate({FX},{FY})">']
    # wall, cut: double line carried past the frame
    s.append(L(830, -60, 830, FH + 34, INK, OBJ)); s.append(L(850, -60, 850, FH + 34, INK, OBJ))
    # table, chairs
    s.append(f'<rect x="150" y="230" width="600" height="600" fill="none" stroke="{INK}" stroke-width="{OBJ}"/>')
    s.append(P('M225,190 H675 V150 Q450,95 225,150 Z', INK, FRAME_W))     # far chair
    s.append(P('M225,870 H675 V910 Q450,965 225,910 Z', INK, FRAME_W))   # near chair (guest's)
    # settings: plate and glass far side; plate and glass near side
    for cy, gy in ((390, 330), (670, 730)):
        s.append(f'<circle cx="450" cy="{cy}" r="120" fill="none" stroke="{INK}" stroke-width="{FRAME_W}"/>')
        s.append(f'<circle cx="450" cy="{cy}" r="78" fill="none" stroke="{INK}" stroke-width="{RAY}"/>')
        s.append(f'<circle cx="640" cy="{gy}" r="34" fill="none" stroke="{INK}" stroke-width="{FRAME_W}"/>')
        s.append(f'<circle cx="640" cy="{gy}" r="27" fill="none" stroke="{INK}" stroke-width="{RAY}"/>')
    # shared plate at the centre line
    s.append(f'<circle cx="270" cy="530" r="70" fill="none" stroke="{INK}" stroke-width="{FRAME_W}"/>')
    # pencil: reach from each shoulder line; the overlap is the shared table
    s.append(P('M-39,752 A520,520 0 0 1 939,752', PENCIL, PEN))
    s.append(P('M-39,308 A520,520 0 0 0 939,308', PENCIL, PEN))
    s.append(L(150, 530, 750, 530, PENCIL, PEN, 'stroke-dasharray="4 6"'))
    # photo layer: shoulders square-cut at the frame's foot, forearms contour-cut onto the table
    s.append('<g clip-path="url(#frame)">')
    k, b = K3, BODY
    sx = 450 - b['shoulder_breadth'] * k / 2
    s.append(f'<rect x="{sx:.0f}" y="870" width="{b["shoulder_breadth"] * k:.0f}" height="90" fill="{PH_BLACK}" filter="url(#grain)"/>')
    # left arm reaches to the shared plate; right arm rests by its own plate
    s.append(limb(280, 890, b['upper_arm_w'] * k * .95, 300, 770, b['elbow_w'] * k * 1.04, fill='url(#cloth)'))
    s.append(limb(300, 770, b['elbow_w'] * k, 300, 575, b['wrist_w'] * k))
    s.append(limb(620, 890, b['upper_arm_w'] * k * .95, 600, 790, b['elbow_w'] * k * 1.04, fill='url(#cloth)'))
    s.append(limb(600, 790, b['elbow_w'] * k, 562, 640, b['wrist_w'] * k, fill=PH_MID))
    hr, hw = b['hand_length'] * k / 2, b['hand_breadth'] * k / 2
    s.append(f'<g filter="url(#grain)"><ellipse cx="296" cy="{575 - hr + 12:.0f}" rx="{hw:.0f}" ry="{hr:.0f}" fill="url(#skin)"/>'
             f'<ellipse cx="548" cy="{640 - hr + 14:.0f}" rx="{hw:.0f}" ry="{hr:.0f}" transform="rotate(-14 548 {640 - hr + 14:.0f})" fill="{PH_MID}"/></g>')
    s.append('</g></g>')
    s.append(frame_and_margin(n, 'TWO-TOP · PLAN · THE REACH THAT MAKES A TABLE SHARED'))
    s.append('</svg>')
    return '\n'.join(s)


# ---- flipbook: hands into the stream and out again ------------------------
def flipbook(count=24):
    FRAMES.mkdir(parents=True, exist_ok=True)
    for old in FRAMES.glob('*.svg'):
        old.unlink()
    keys = [(330, 470, 4), (500, 445, 10), (580, 440, 12), (586, 446, 15), (574, 436, 9),
            (586, 446, 15), (580, 440, 12), (500, 445, 10)]
    for f in range(count):
        t = f / count * len(keys)
        i, u = int(t), t - int(t)
        u = u * u * (3 - 2 * u)                     # ease between keys
        a, b = keys[i], keys[(i + 1) % len(keys)]
        hx, hy, rot = (a[k] + (b[k] - a[k]) * u for k in range(3))
        svg = hand_sink(hx, hy, rot, jitter=1.4, seed=f, n=1)
        (FRAMES / f'frame-{f:03d}.svg').write_text(svg)


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    suffix = '-warm' if WARM else ''
    (OUT / f'plate-01-hand-sink{suffix}.svg').write_text(hand_sink())
    (OUT / f'plate-02-bar-rail{suffix}.svg').write_text(bar_rail())
    (OUT / f'plate-03-two-top{suffix}.svg').write_text(two_top())
    if not WARM:
        flipbook()
    print('wrote', OUT)
