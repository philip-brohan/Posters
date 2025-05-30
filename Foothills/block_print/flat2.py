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

from Met_palettes import MET_PALETTES

mCols = list(MET_PALETTES["Pillement"]["colors"])
# mCols.reverse()
mCmap = matplotlib.colors.LinearSegmentedColormap.from_list("Test", mCols)

view_lon = -105.18807
view_lat = 39.96774
# 3716,2920 in pixel coordinates
view_height = 1721 + 200  # m

# Adjust coordinates for distance - scale them so they
# are as they woud appear on a plane 1km away
def project_coordinates(lat, lon, height):
    dlat = 0  # in m
    dlon = (view_lon - lon) * 85000
    dheight = height - view_height
    distance = dlon
    sheight = (dheight / distance) * 1000
    slat = lat
    return (slat, sheight)


lat_min = view_lat - 0.41
lat_max = view_lat + 0.41
p_lat_min = lat_min
p_lat_max = lat_max

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
bottom = -100
top = 100

axb = fig.add_axes([0, 0, 1, 1])
axb.set_axis_off()
axb.set_xlim(p_lat_min, p_lat_max)
axb.set_ylim(bottom, top)
axb.set_aspect("auto")
lat_scale = p_lat_max - p_lat_min
height_scale = top - bottom
aspect_scale = (height_scale / lat_scale) * (20 / 7)
s = (2000, 700)
sun_x = 0.0 * lat_scale + p_lat_min
sun_y = 0.4 * height_scale + bottom
y = np.linspace(bottom, top, s[1])
x = np.linspace(p_lat_min, p_lat_max, s[0])
xm, ym = np.meshgrid(x, y)
xm = xm - sun_x
ym = 4 * (ym - sun_y) / aspect_scale
nd2 = np.sqrt(xm * xm + ym * ym)
nd2 /= np.max(nd2)
nd2 = np.sqrt(nd2)
nd2 += np.random.rand(s[1], s[0]) * 0.1
sCols = list(MET_PALETTES["Hiroshige"]["colors"])
# sCols = list(MET_PALETTES["Troy"]["colors"])
# sCols.reverse()
sCmap = matplotlib.colors.LinearSegmentedColormap.from_list("Sun", sCols)

img = axb.pcolormesh(x, y, nd2, cmap=sCmap, alpha=1.0, shading="gouraud", zorder=1)


def make_line(lon_idx, shift=0, rfr=0.5):
    height = rdata[:, lon_idx]
    llats = lats[:, lon_idx]
    llons = lons[:, lon_idx]
    (l_lats, l_heights) = project_coordinates(llats, llons, height)
    #print(l_heights)
    #print(l_lats)
    #sys.exit(0)
    if shift != 0:
        sscale = 1.0 - rfr + np.random.random(len(l_lats)) * rfr
        lld = np.concatenate((np.zeros(1), np.diff(l_lats))) * shift * sscale
        l_lats += lld
    return (l_lats, l_heights)


def make_poly(idx1, idx2, shift=0):
    lats1, heights1 = make_line(idx1, shift=shift)
    lats2, heights2 = make_line(idx2, shift=shift)
    return (
        np.concatenate((lats1, np.flip(lats2))),
        np.concatenate((heights1, np.flip(heights2))),
    )


def lighten(colour, scale=1.0):
    col = (
        max(0.0, min(1.0, colour[0] * scale)),
        max(0.0, min(1.0, colour[1] * scale)),
        max(0.0, min(1.0, colour[2] * scale)),
        colour[3],
    )
    return col


def plot_layer(idx1, idx2, colour):
    px, py = make_poly(idx1, idx2, shift=1)
    py = py[(px > p_lat_min * 0.95) & (px < p_lat_max * 1.05)]
    px = px[(px > p_lat_min * 0.95) & (px < p_lat_max * 1.05)]
    mask_img = axb.fill(
        px,
        py,
        facecolor=lighten(col, 1.2),
        edgecolor="white",
        lw=0.0,
        zorder=idx2 * 10,
    )
    px, py = make_poly(idx1, idx2, shift=-1)
    py = py[(px > p_lat_min * 1.1) & (px < p_lat_max * 1.05)]
    px = px[(px > p_lat_min * 1.1) & (px < p_lat_max * 1.05)]
    mask_img = axb.fill(
        px,
        py,
        facecolor=lighten(col, 0.8),
        edgecolor="white",
        lw=0.0,
        zorder=idx2 * 10,
    )
    px, py = make_line(int((idx1 + idx2) / 2))
    py = py[(px > p_lat_min * 1.1) & (px < p_lat_max * 1.05)]
    px = px[(px > p_lat_min * 1.1) & (px < p_lat_max * 1.05)]
    mean_line = axb.plot(px, py, "-", color=(0, 0, 0, 1), lw=0.1, zorder=idx2 * 10 + 19)


for lon_idx in range(1, 2920, 1):
    ifrac = max(1, int((2920 - lon_idx) / 200))
    # if lon_idx % ifrac != 0:
    #    continue
    lon = lons[:, lon_idx][0]
    if lon > (view_lon - 0.1):
        continue
    cscale = lon_idx / 3600
    col = (1 - cscale, 1 - cscale, 1 - cscale, 1.0)
    col = mCmap(np.sqrt(max(0, min(1, (2920 - lon_idx) / 2920))))
    plot_layer(lon_idx - (ifrac + 1), lon_idx, col)

fig.savefig("Flat.png")
