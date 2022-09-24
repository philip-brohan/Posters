#!/usr/bin/env python

# Make a woodblock-print style picture of the Front Range from DEM data

import os
import sys
import rasterio
import numpy as np

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib.patches import Rectangle

import cmocean

view_lon = -100.08807
# view_lat = 39.96774
view_lat = 39.96774
# 3716,2920 in pixel coordinates
view_height = 1721 + 200  # m


lat_min = 39.75
lat_max = 40.25

img = rasterio.open("%s/DEM/Boulder.tif" % os.getenv("SCRATCH"))
rdata = img.read(1)
height = rdata.shape[0]
width = rdata.shape[1]
cols, rows = np.meshgrid(np.arange(width), np.arange(height))
xs, ys = rasterio.transform.xy(img.transform, rows, cols)
lons = np.array(xs)
lats = np.array(ys)

fig = Figure(
    figsize=(20, 5),  # Width, Height (inches)
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
bottom = 1550
top = 5000

axb = fig.add_axes([0, 0, 1, 1])
axb.set_axis_off()
axb.set_xlim(lat_min, lat_max)
axb.set_ylim(bottom, top)
axb.set_aspect("auto")
axb.add_patch(
    Rectangle(
        (lat_min, bottom),
        lat_max - lat_min,
        top - bottom,
        facecolor=(0.25, 0.65, 0.95, 1),
        fill=True,
        zorder=1,
    )
)


def plot_layer(lon_idx, colour, dlon):
    height_series = rdata[:, lon_idx] + dlon * 0
    llats = lats[:, lon_idx]
    height_series = height_series[(llats > lat_min) & (llats < lat_max)]
    llats = llats[(llats > lat_min) & (llats < lat_max)]
    poly_y = np.concatenate((height_series, np.zeros(height_series.shape) + bottom))
    poly_x = np.concatenate((llats, np.flip(llats)))
    cscale = 1 - (height - lon_idx) / (height)
    c_left = min(cscale * 1.1, 1.0)
    c_left = (c_left, c_left, c_left, 1)
    offset = np.random.random(len(llats) * 2) * 0.0005 + 0.0005
    mask_img = axb.fill(
        poly_x - offset,
        poly_y,
        facecolor=c_left,
        edgecolor="white",
        lw=0.0,
        zorder=lon_idx,
    )
    c_right = (cscale * 0.9, cscale * 0.9, cscale * 0.9, 1)
    mask_img = axb.fill(
        poly_x + offset,
        poly_y,
        facecolor=c_right,
        edgecolor="white",
        lw=0.05,
        zorder=lon_idx,
    )
    mask_img = axb.fill(
        poly_x,
        poly_y,
        facecolor=(0, 0, 0, 0),
        edgecolor="black",
        lw=0.05,
        zorder=lon_idx + 1,
    )


for lon_idx in range(0, height, 3):
    lon = lons[:, lon_idx][0]
    # if lon>(view_lon-0.001): continue
    cscale = (height - lon_idx) / (height)
    col = (1 - cscale, 1 - cscale, 1 - cscale, 1.0)
    plot_layer(lon_idx, col, dlon=view_lon - lon)

fig.savefig("Blocks.png")
