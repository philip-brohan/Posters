#!/usr/bin/env python

# Plot daily CET as a rectangle - years on the x axis, days on the y axis.

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure

import numpy
from pandas import qcut



s=t2m.data.shape
t2m.data=numpy.ma.array(qcut(t2m.data.flatten(),100,labels=False,
                             duplicates='drop').reshape(s),
                        mask=t2m.data.mask)

# Define the figure (page size, background color, resolution, ...
fig=Figure(figsize=(48.8,33.1),              # A0 - Width, Height (inches)
           dpi=300,
           facecolor=(0.5,0.5,0.5,1),
           edgecolor=None,
           linewidth=0.0,
           frameon=False,               
           subplotpars=None,
           tight_layout=None)
fig.set_frameon(False) 
# Attach a canvas
canvas=FigureCanvas(fig)

ax = fig.add_axes([0,0,1,1])
ax.set_axis_off() # Don't want surrounding x and y axis

# Lat and lon range (in rotated-pole coordinates) for plot
ax.set_xlim(-180,180)
ax.set_ylim(-90,90)
ax.set_aspect('auto')

lats = t2m.coord('latitude').points
lons = t2m.coord('longitude').points
sst_img = ax.pcolorfast(lons, lats, t2m.data,
                        cmap='RdYlBu_r',
                        alpha=1.0,
                        vmin=0,
                        vmax=102,
                        zorder=100)
