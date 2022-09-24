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

view_lon = -105.18807
# view_lat = 39.96774
view_lat = 39.96774
# 3716,2920 in pixel coordinates
view_height = 1721 + 200  # m

# Adjust coordinates for distance - scale them so they
# are as they woud appear on a plane 1km away
def project_coordinates(lat, lon, height):
    dlat = (lat - view_lat) * 111000  # in m
    dlon = (view_lon - lon) * 85000
    dheight = height - view_height
    distance = np.sqrt(dlat ** 2 + dlon ** 2)
    sheight = (dheight / distance) * 1000
    slat = (dlat / dlon) * 1000
    return (slat, sheight)


lat_min = 39.75
lat_max = 40.25
p_lat_min = project_coordinates(39.75, view_lon - 1 / 111, view_height)[0] / 40
p_lat_max = project_coordinates(40.25, view_lon - 1 / 111, view_height)[0] / 40

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
bottom = -200
top = 100

axb = fig.add_axes([0, 0, 1, 1])
axb.set_axis_off()
axb.set_xlim(p_lat_min, p_lat_max)
axb.set_ylim(bottom, top)
axb.set_aspect("auto")
axb.add_patch(
    Rectangle(
        (p_lat_min, bottom),
        p_lat_max - p_lat_min,
        top - bottom,
        facecolor=(0.25, 0.65, 0.95, 1),
        fill=True,
        zorder=1,
    )
)
lat_scale = p_lat_max - p_lat_min


def plot_layer(lon_idx, colour):
    height_series = rdata[:, lon_idx]
    llats = lats[:, lon_idx]
    llons = lons[:, lon_idx]
    (p_lats, p_heights) = project_coordinates(llats, llons, height_series)
    height_series = p_heights[
        (p_lats > (p_lat_min * 1.1)) & (p_lats < p_lat_max * 1.05)
    ]
    llats = p_lats[(p_lats > p_lat_min * 1.1) & (p_lats < p_lat_max * 1.05)]
    poly_y = np.concatenate((height_series, np.zeros(height_series.shape) + bottom))
    poly_x = np.concatenate((llats, np.flip(llats)))
    cscale = lon_idx / 3600
    cscale = 0.5
    col = (
        min((1 - cscale) * 1.1, 1),
        min((1 - cscale) * 1.1, 1),
        min((1 - cscale) * 1.1, 1),
        1.0,
    )
    mask_img = axb.fill(
        poly_x - lat_scale / 1000,
        poly_y,
        facecolor=col,
        edgecolor="white",
        lw=0.0,
        zorder=lon_idx * 10,
    )
    col = (
        min((1 - cscale) * 0.9, 1),
        min((1 - cscale) * 0.9, 1),
        min((1 - cscale) * 0.9, 1),
        1.0,
    )
    mask_img = axb.fill(
        poly_x + lat_scale / 1000,
        poly_y,
        facecolor=col,
        edgecolor="white",
        lw=0.0,
        zorder=lon_idx * 10,
    )
    mask_img = axb.fill(
        poly_x,
        poly_y,
        facecolor=(0, 0, 0, 0),
        edgecolor="white",
        lw=0.1,
        zorder=lon_idx * 10 + 9,
    )


for lon_idx in range(359, 3600, 1):
    lon = lons[:, lon_idx][0]
    if lon > (view_lon - 0.001):
        continue
    cscale = lon_idx / 3600
    col = (1 - cscale, 1 - cscale, 1 - cscale, 1.0)
    plot_layer(lon_idx, col)

fig.savefig("Blocks.png")
