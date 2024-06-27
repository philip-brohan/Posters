#!/usr/bin/env python

# Re-draw Durer's Rhinoceros using Matplotlib
# This version with a dark background and a different figure aspect for use as a laptop wrap

import sys
import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib.patches import Polygon
from matplotlib import font_manager

from PIL import Image
import numpy as np
from utils import smoothLine, viridis, colours

# Load the original
bg_im = Image.open(r"The_Rhinoceros_(NGA_1964.8.697)_enhanced.png")
bg_im = bg_im.convert("RGB")
# Convert to numpy array on 0-1
bg_im = np.array(bg_im) / 255.0

# Figure setup
fig = Figure(
    figsize=(1.1*3000 / 100, 1.1*2368 / 100),  # Width, Height (inches)
    dpi=300,
    facecolor=colours["background"],
    edgecolor=None,
    linewidth=0.0,
    frameon=True,
    subplotpars=None,
    tight_layout=None,
)
canvas = FigureCanvas(fig)
font = {"family": "sans-serif", "sans-serif": "Arial", "weight": "normal", "size": 18}
matplotlib.rc("font", **font)

# Put image in as background - hidden in final result
axb = fig.add_axes([0, 0, 1, 1])
axb.set_axis_off()
axb.set_xlim(0, 1)
axb.set_ylim(0, 1)
# Add the image
bgi_extent = [0.03+.05, 0.98-.05, 0.03+.05, 0.98-0.05]
# axb.imshow(bg_im, extent=bgi_extent, aspect="auto", alpha=0.5)

# Add a textured grey background
s=(1200,800)
axbg = fig.add_axes([0,0,1,1],facecolor='green')
axbg.set_axis_off() # Don't want surrounding x and y axis
nd2=np.random.rand(s[1],s[0])
clrs=[]
for shade in np.linspace(.42+.01,.36+.01):
    clrs.append((shade,shade,shade,1))
y = np.linspace(0,1,s[1])
x = np.linspace(0,1,s[0])
img = axbg.pcolormesh(x,y,nd2,
                        cmap=matplotlib.colors.ListedColormap(clrs),
                        alpha=1.0,
                        shading='gouraud',
                        zorder=10)


# Add a grid of axes
gspec = matplotlib.gridspec.GridSpec(
    ncols=4,
    nrows=5,
    figure=fig,
    width_ratios=[
        1.5,
        1.5,
        1.5,
        1.5,
    ],
    height_ratios=[1, 1, 1, 1, 1],
    wspace=0.1,
    hspace=0.1,
)
# Set the space the subplots take up
fig.subplots_adjust(left=0.02+0.05, right=0.99-0.05, bottom=0.02+0.05, top=0.9-0.05)


# Each subplot has a separate function to draw it

# Top Left
from pTL import pTL

ax_TL = pTL(fig, gspec[0, 0])

# Top Centre Left
from pTCL import pTCL

ax_TCL = pTCL(fig, gspec[0, 1])

# Top Right and Centre Right
from pTCR_TR import pTCR_TR

ax_TCR_TR = pTCR_TR(fig, gspec[0, 2:4])

# 2nd Left
from p2L import p2L

ax_2L = p2L(fig, gspec[1, 0])

# 2nd and 3rd Centre Left
from p2CL_3CL import p2CL_3CL

ax_2CL_3CL = p2CL_3CL(fig, gspec[1:3, 1])

# 2nd Centre Right
from p2CR import p2CR

ax_2CR = p2CR(fig, gspec[1, 2])

# 2nd Right
from p2R import p2R

ax_2R = p2R(fig, gspec[1, 3], bg_im, bgi_extent)

# 3rd Left
from p3L import p3L

ax_3L = p3L(fig, gspec[2, 0])

# 3rd Centre Right
from p3CR import p3CR

ax_3CR = p3CR(fig, gspec[2, 2])

# 3rd and 4th Right
from p3R_4R import p3R_4R

ax_3R_4R = p3R_4R(fig, gspec[2:4, 3], bg_im, bgi_extent)

# 4th and 5th Left
from p4L_5L import p4L_5L

ax_4L_5L = p4L_5L(fig, gspec[3:5, 0])

# 4th Centre Left
from p4CL import p4CL

ax_4CL = p4CL(fig, gspec[3, 1])

# 4th and 5th Centre Right
from p4CR_5CR import p4CR_5CR

ax_4CR_5CR = p4CR_5CR(fig, gspec[3:5, 2])

# 5th Centre Left
from p5CL import p5CL

ax_5CL = p5CL(fig, gspec[4, 1])

# 5th Right
from p5R import p5R

ax_5R = p5R(fig, gspec[4, 3])

# Paint the axis spines and tics in a light colour to contrast with the dark background
for ax in fig.get_axes():
    # Set tick color
    ax.tick_params(colors=(colours["ax_bg"]))
    
    # Set tick label color
    ax.xaxis.label.set_color(colours["ax_bg"])  
    ax.yaxis.label.set_color(colours["ax_bg"])  
    for spine in ax.spines.values():
        spine.set_edgecolor(colours["ax_bg"])  

# Render the new image
fig.savefig("modern_rhinoceros_wrap.webp")
