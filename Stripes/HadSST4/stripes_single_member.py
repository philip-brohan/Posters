#!/usr/bin/env python

# Make a poster showing HadSST4 monthly temperatures.
# Inspired by the climate stripes popularised by Ed Hawkins.

import os
import iris
import numpy
import datetime

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib.patches import Rectangle

from pandas import qcut

# Choose one ensemble member (arbitrarily)
member = 87

# Load the 20CR data
h=iris.load_cube("/scratch/hadcc/hadcrut5/build/HadSST4/analysis/"+
                 "HadCRUT.5.0.0.0.SST.analysis.anomalies.%d.nc" % member)

# Pick a random longitude at each month
p=h.extract(iris.Constraint(longitude=0))
s=h.data.shape
for t in range(s[0]):
   for lat in range(s[1]):
       rand_l = numpy.random.randint(0,s[2])
       p.data[t,lat]=h.data[t,lat,rand_l]
h=p
ndata=h.data

# Plot the resulting array as a 2d colourmap
fig=Figure(figsize=(72,18),              # Width, Height (inches)
           dpi=300,
           facecolor=(0.5,0.5,0.5,1),
           edgecolor=None,
           linewidth=0.0,
           frameon=False,                # Don't draw a frame
           subplotpars=None,
           tight_layout=None)
#fig.set_frameon(False) 
# Attach a canvas
canvas=FigureCanvas(fig)
matplotlib.rc('image',aspect='auto')

# Speckled grey background
s=ndata.shape
ax2 = fig.add_axes([0,0,1,1],facecolor='green')
ax2.set_axis_off() # Don't want surrounding x and y axis
nd2=numpy.random.rand(s[1],s[0])
clrs=[]
for shade in numpy.linspace(.42+.01,.36+.01):
    clrs.append((shade,shade,shade,1))
y = numpy.linspace(0,1,s[1])
x = numpy.linspace(0,1,s[0])
img = ax2.pcolormesh(x,y,nd2,
                        cmap=matplotlib.colors.ListedColormap(clrs),
                        alpha=1.0,
                        shading='gouraud',
                        zorder=10)

ax = fig.add_axes([0,0,1,1],facecolor='black',xlim=(0,1),ylim=(0,1))
ax.set_axis_off() # Don't want surrounding x and y axis

ndata=numpy.transpose(ndata)
s=ndata.shape
y = numpy.linspace(0,1,s[0])
x = numpy.linspace(0,1,s[1])
img = ax.pcolorfast(x,y,numpy.cbrt(ndata),
                        cmap='RdYlBu_r',
                        alpha=1.0,
                        vmin=-1.7,
                        vmax=1.7,
                        zorder=100)

fig.savefig('m%d.pdf' % member)
