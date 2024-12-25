#!/usr/bin/env python

# Re-draw Durer's 'Self portrait at 28' using Matplotlib

import sys
import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib.patches import Polygon
from matplotlib import font_manager

from PIL import Image
import numpy as np

# from utils import smoothLine, viridis, colours

viridis = matplotlib.colormaps["viridis"]

colours = {
    "yellow": viridis.colors[255],
    "green": viridis.colors[200],
    "blue": viridis.colors[100],
    "purple": viridis.colors[0],
    "background": (242 / 255, 231 / 255, 218 / 255, 1),
    "transparent": (1, 1, 1, 0.5),
    "ax_bg": (0.975, 0.953, 0.927, 1),  # background+transparent
}


# Load the original
bg_im = Image.open(r"Face.jpeg")
bg_im = bg_im.convert("RGB")
# Convert to numpy array on 0-1
bg_im = np.array(bg_im) / 255.0
# Convert to greyscale
bg_im = np.mean(bg_im, axis=2)
# gamma = 0.5  # Example gamma value
# bg_im = np.power(bg_im, 1 / gamma)

# Quantize the image
bg_im = np.round(bg_im * 255).astype(np.uint8)

# Figure setup
fig = Figure(
    figsize=(2121 / 100, 1798 / 100),  # Width, Height (inches)
    dpi=300,
    facecolor=colours["background"],
    edgecolor=None,
    linewidth=0.0,
    frameon=True,
    subplotpars=None,
    tight_layout=None,
)
canvas = FigureCanvas(fig)
font = {"family": "sans-serif", "sans-serif": "Arial", "weight": "normal", "size": 28}
matplotlib.rc("font", **font)

# Put image in as background - hidden in final result
axb = fig.add_axes([0.05, 0.05, 0.95, 0.95])
# axb.set_axis_off()
axb.set_xlim(0, 1)
axb.set_ylim(0, 1)
# Add the image
bgi_extent = [0.0, 1.0, 0.0, 1.0]
axb.imshow(bg_im, extent=bgi_extent, aspect="auto", alpha=0.5, cmap="grey", zorder=0)
axb.set_xticks(np.linspace(0.1, 0.9, 9))
axb.set_xticks(np.linspace(0.01, 0.99, 99), minor=True)
axb.set_yticks(np.linspace(0.1, 0.9, 9))
axb.set_yticks(np.linspace(0.01, 0.99, 99), minor=True)
axb.grid(
    visible=True,
    which="minor",
    axis="both",
    color="red",
    linestyle="-",
    linewidth=0.5,
    zorder=50,
)
axb.grid(
    visible=True,
    which="major",
    axis="both",
    color="red",
    linestyle="-",
    linewidth=2,
    zorder=100,
)


# Each subplot has a separate function to draw it

# Top Left
# from pTL import pTL

# ax_TL = pTL(fig, gspec[0, 0])


# Render the new image
fig.savefig("portrait.webp")
