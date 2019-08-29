#!/usr/bin/env python

# Ocean-centred projection. Equirectangular, but inspired by Spilhaus.

import Meteorographica as mg
import iris

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
import cartopy
import cartopy.crs as ccrs

import pkg_resources
import gzip
import pickle

# Define the figure (page size, background color, resolution, ...
aspect=16/9.0
fig=Figure(figsize=(22,22/aspect),              # Width, Height (inches)
           dpi=100,
           facecolor=(0.88,0.88,0.88,1),
           edgecolor=None,
           linewidth=0.0,
           frameon=False,                # Don't draw a frame
           subplotpars=None,
           tight_layout=None)
fig.set_frameon(False) 
# Attach a canvas
canvas=FigureCanvas(fig)

# Lat:Lon aspect does not match the plot aspect, ignore this and
#  fill the figure with the plot.
matplotlib.rc('image',aspect='auto')

# All mg plots use Rotated Pole: choose a rotation that approximates the
# Spilhaus projection - bordered by land, ocean in the middle.
projection=ccrs.RotatedPole(pole_longitude=113.0,
                                pole_latitude=32.0,
                                central_rotated_longitude=193.0)

# Define an axes to contain the plot. In this case our axes covers
#  the whole figure
ax = fig.add_axes([22/(360+22),0,360/(360+22),1],projection=projection)
ax.set_axis_off() # Don't want surrounding x and y axis
# Set the axes background colour
ax.background_patch.set_facecolor((0.88,0.88,0.88,1))

# Lat and lon range (in rotated-pole coordinates) for plot
extent=[0.0,180.0,-90.0,90.0]
ax.set_extent(extent, crs=projection)
ax.set_xlim([-180, 180])

# Draw a lat:lon grid
mg.background.add_grid(ax,
                       sep_major=5,
                       sep_minor=2.5,
                       color=(0,0.3,0,0.2))


# Add the land
land_img=ax.background_img(name='GreyT', resolution='low')


# Subsidiary axes to allow more than -180:180 as range
ax = fig.add_axes([0,0,22/(360+22),1],projection=projection)
ax.set_axis_off() # Don't want surrounding x and y axis
# Set the axes background colour
ax.background_patch.set_facecolor((0.88,0.88,0.88,1))

# Lat and lon range (in rotated-pole coordinates) for plot
extent=[158,180.0,-90.0,90.0]
ax.set_extent(extent, crs=projection)
ax.set_xlim([158, 180])

# Draw a lat:lon grid
mg.background.add_grid(ax,
                       sep_major=5,
                       sep_minor=2.5,
                       color=(0,0.3,0,0.2))


# Add the land
land_img=ax.background_img(name='GreyT', resolution='low')


# Render the figure as a png
fig.savefig('plain.png')
