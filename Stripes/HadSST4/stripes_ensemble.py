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

# Choose ten ensemble members (Should be half odd and half even,
#   and half from 1-50, half from 51-100)
members = (1,2,3,4,5,56,57,58,59,60)

# Load the data
h=[]
for member in members:
    h.append(iris.load_cube("/scratch/hadcc/hadcrut5/build/HadSST4/analysis/"+
                 "HadCRUT.5.0.0.0.SST.analysis.anomalies.%d.nc" % member))

# Pick a random longitude at each month
s=h[0].data.shape
ndata=numpy.ma.array(numpy.zeros((s[0],s[1]*10)),mask=True)
for member in range(len(h)):
    for t in range(s[0]):
       for lat in range(s[1]):
           rand_l = numpy.random.randint(0,s[2])
           ndata[t,(lat*10+member)]=h[member].data[t,lat,rand_l]

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

fig.savefig('ensemble.pdf')
