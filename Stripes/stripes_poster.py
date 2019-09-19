#!/usr/bin/env python

# Make a poster showing HadCRUT data.
# Inspired by the climate stripes popularised by Ed Hawkins.

import os
import iris
import geohash2
import numpy

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib.patches import Rectangle

from pandas import qcut

# Load the HadCRUT4 data
h=iris.load_cube('%s/Posters/HadCRUT/HadCRUT.4.6.0.0.median.nc' %
            os.getenv('SCRATCH'),'near_surface_temperature_anomaly')
# Convert each lat:lon position to a geohash
ghl=[]
for lat in h.coord('latitude').points:
        for lon in h.coord('longitude').points:
            ghl.append(geohash2.encode(lat, lon, precision=5))
# Reshape the HadCRUT4 data from lat:lon into a single location coord
s=h.data.shape
ndata=h.data.reshape((s[0],s[1]*s[2]))
# Sort the location coords alphabetically by geohash
#  Should produce a 1d-array with 2d-close locations close in the 1d.
for t in range(s[0]):
    ndata[t,:]=[x for _,x in sorted(zip(ghl,ndata[t,:]))]

# Plot the resulting array as a 2d colourmap
fig=Figure(figsize=(50,25),              # Width, Height (inches)
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
ax = fig.add_axes([0,0,1,1],facecolor='black',xlim=(0,1),ylim=(0,1))
ax.set_axis_off() # Don't want surrounding x and y axis
# Axes ignores facecolor, so set background explicitly
ax.add_patch(Rectangle((0,0),1,1,facecolor=(0.88,0.88,0.88,1),fill=True,zorder=1))

ndata=numpy.transpose(ndata)
s=ndata.shape
ndata=numpy.ma.array(qcut(ndata.flatten(),200,labels=False,
                             duplicates='drop').reshape(s),
                        mask=ndata.mask)
y = numpy.linspace(0.001,0.999,s[0])
x = numpy.linspace(0.001,0.999,s[1])
img = ax.pcolormesh(x,y,ndata,
                        cmap='RdYlBu_r',
                        alpha=1.0,
                        shading='flat',
                        vmin=10,
                        zorder=100)

# Textured background
nd2=numpy.random.rand(s[0],s[1])
clrs=[]
for shade in numpy.linspace(.82,.96):
    clrs.append((shade,shade,shade,1))
y = numpy.linspace(0.001,0.999,s[0])
x = numpy.linspace(0.001,0.999,s[1])
img = ax.pcolormesh(x,y,nd2,
                        cmap=matplotlib.colors.ListedColormap(clrs),
                        alpha=1.0,
                        shading='gouraud',
                        zorder=10)

fig.savefig('HadCRUT4.png')
