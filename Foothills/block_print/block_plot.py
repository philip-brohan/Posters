#!/usr/bin/env python

# Make a woodblock-print style picture of the Front Range from DEM data

import os
import rasterio
import numpy as np

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib.patches import Rectangle

import cmocean

img = rasterio.open("%s/DEM/Boulder.tif" % os.getenv("SCRATCH"))
aspect = (img.bounds.top - img.bounds.bottom) / (img.bounds.right - img.bounds.left)
rdata = img.read(1)
height = rdata.shape[0]
width = rdata.shape[1]
cols, rows = np.meshgrid(np.arange(width), np.arange(height))
xs, ys = rasterio.transform.xy(img.transform, rows, cols)
lons = np.array(xs)
lats = np.array(ys)

fig = Figure(
    figsize=(20,5),  # Width, Height (inches)
    dpi=300,
    facecolor=(0.5, 0.5, 0.5, 1),
    edgecolor=None,
    linewidth=0.0,
    frameon=False,  # Don't draw a frame
    subplotpars=None,
    tight_layout=None,
)
fig.set_frameon(False)
# Attach a canvas
canvas = FigureCanvas(fig)

# Scale height range for the plot (m)
bottom=1500
top=5000

axb = fig.add_axes([0, 0, 1, 1])
axb.set_axis_off()
axb.set_xlim(np.min(lats), np.max(lats))
axb.set_ylim(bottom, top)
axb.set_aspect("auto")
axb.add_patch(
    Rectangle((np.min(lats), bottom), np.max(lats)-np.min(lats), top-bottom, facecolor=(0.25, 0.65, 0.95, 1), fill=True, zorder=1,)
)


def plot_layer(lon_idx,colour):
    height_series = rdata[:,lon_idx]
    poly_y = np.concatenate((height_series,np.zeros(height_series.shape)))
    poly_x = np.concatenate((lats,np.flip(lats)))
    mask_img = axb.fill(
        poly_x, poly_y, color=colour, zorder=lon_idx
    )

for lon_idx in range(359,3600,720):
   col = (0.0,0.0,0.0,lon_idx/3600)
   plot_layer(lon_idx,col)

fig.savefig("Blocks.png")
