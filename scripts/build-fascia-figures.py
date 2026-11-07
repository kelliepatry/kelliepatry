"""Conceptual, text-free editorial figures. No live records or measured data.
Requires matplotlib. Rebuild from repository root: python scripts/build-fascia-figures.py
Captions and semantic labels live in articles/flip-the-paper.md, using GitHub's native type.
"""
from pathlib import Path
import math
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Circle, Rectangle, FancyArrowPatch
ROOT=Path(__file__).resolve().parents[1]/'assets'/'fascia'
ROOT.mkdir(parents=True,exist_ok=True)
INK='#161615'; MID='#7C7C79'; FAINT='#C6C6C3'; BG='#F4F4F2'
plt.rcParams['svg.hashsalt']='kphd-fascia-editorial04'
def canvas():
    fig,ax=plt.subplots(figsize=(16,8),dpi=100)
    fig.patch.set_facecolor(BG);ax.set_facecolor(BG)
    ax.set(xlim=(0,16),ylim=(0,8),aspect='equal');ax.axis('off')
    fig.subplots_adjust(0,0,1,1)
    return fig,ax
def line(ax,a,b,color=INK,lw=1.3,style='-'):
    ax.plot([a[0],b[0]],[a[1],b[1]],c=color,lw=lw,ls=style,zorder=1)
def node(ax,p,r=.07,color=INK):ax.add_patch(Circle(p,r,facecolor=color,edgecolor='none',zorder=4))
def arrow(ax,a,b,color=INK,rad=0,style='-'):
    ax.add_patch(FancyArrowPatch(a,b,arrowstyle='->',mutation_scale=16,linewidth=1.4,color=color,connectionstyle=f'arc3,rad={rad}',linestyle=style))
def frame(ax,x,y,w=1.7,h=1.9,style='-',color=INK):
    ax.add_patch(Rectangle((x,y),w,h,fill=False,ec=color,lw=1.3,ls=style,zorder=2))
    for fraction in [.25,.5,.75]:line(ax,(x+.24,y+h*fraction),(x+w-.24,y+h*fraction),FAINT,.9)
def save(fig,name):
    fig.savefig(ROOT/f'{name}.png',dpi=100,facecolor=BG)
    fig.savefig(ROOT/f'{name}.svg',facecolor=BG,metadata={'Date':None,'Description':'Conceptual illustration; no live system data or quantitative spatial encoding.'})
    plt.close(fig)
fig,ax=canvas()
for i in range(5):
    x=1.05+i*2.9; frame(ax,x,3.2)
    if i<4:arrow(ax,(x+1.8,4.2),(x+2.8,4.2),MID)
frame(ax,12.45,2.95,2.1,2.45)
arrow(ax,(13.7,2.5),(1.9,2.5),INK,rad=-.13)
save(fig,'outcome-inward')
fig,ax=canvas()
a=(2.6,4.1); b=(7,5.4); c=(7,2.6)
node(ax,a,.13); frame(ax,9,4.65,2.15,1.6);frame(ax,9,1.7,2.15,1.6)
arrow(ax,a,(8.8,5.4),MID);arrow(ax,a,(8.8,2.5),MID)
frame(ax,4.7,6.4,1.8,.9,'--',MID);arrow(ax,a,(4.5,6.75),MID,style='--')
node(ax,(2.6,1.15),.13);arrow(ax,(2.6,1.4),(2.6,3.8));arrow(ax,(2.9,1.15),(8.85,2.5),INK,rad=.14);arrow(ax,(2.9,1.15),(8.85,5.4),INK,rad=.33)
for p in [(13,5.6),(13.8,4.1),(13,2.6)]: ax.add_patch(Circle(p,.13,fill=False,ec=FAINT,lw=1.1,ls='--'))
save(fig,'correction')
fig,ax=canvas()
# Deterministic Fibonacci sphere: spacing and edges are purely illustrative.
pts=[]
for i in range(170):
    y=1-2*(i+.5)/170;r=math.sqrt(1-y*y);ang=i*math.pi*(3-math.sqrt(5))
    x,z=r*math.cos(ang),r*math.sin(ang)
    pts.append((4.2+2.6*x,4+2.6*y,z))
for i,(x,y,z) in enumerate(pts):
    nearest=sorted(range(len(pts)),key=lambda j:(pts[j][0]-x)**2+(pts[j][1]-y)**2+((pts[j][2]-z)*2.6)**2)[1:5]
    for j in nearest:
        if j>i:line(ax,(x,y),pts[j][:2],FAINT if z<0 else MID,.35 if z<0 else .65)
    node(ax,(x,y),.015 if z<0 else .025,FAINT if z<0 else INK)
ax.add_patch(Circle((4.2,4),2.62,fill=False,ec=MID,lw=.65))
ax.add_patch(Circle((11.9,4),2.62,fill=False,ec=FAINT,lw=.7,ls='--'))
route=[(9.7,3),(10.45,4.55),(11.35,3.8),(12.25,5.05),(13.15,4.35),(14.05,3)]
for a,b in zip(route,route[1:]):arrow(ax,a,b)
for p in route:node(ax,p,.09)
arrow(ax,route[-1],route[0],MID,rad=-.45)
save(fig,'two-perspectives')
print('Wrote three SVG masters and three PNG figures.')
