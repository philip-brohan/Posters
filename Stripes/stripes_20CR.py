#!/usr/bin/env python

# Make a poster showing 20CR monthly temperatures.
# Inspired by the climate stripes popularised by Ed Hawkins.

import os
import iris
#import geohash2
import numpy
import datetime

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib.patches import Rectangle

from pandas import qcut

# Load the 20CR data
h=iris.load_cube('./air.2m.mon.mean.nc','air_temperature')
# Get the climatology
n=[]
for m in range(1,13):
    mc=iris.Constraint(time=lambda cell: cell.point.month == m and cell.point.year>1700 and cell.point.year<1869)
    n.append(h.extract(mc).collapsed('time', iris.analysis.MEAN))

# Anomalise
for tidx in range(len(h.coord('time').points)):
    tpt=datetime.datetime(1800,1,1)+datetime.timedelta(hours=h.coord('time').points[tidx])
    midx=tpt.month-1
    h.data[tidx,:,:] -= n[midx].data

# Average over longitude
h=h.collapsed('longitude', iris.analysis.MEAN)
#h=h.extract(iris.Constraint(longitude=0))
#h=h.extract(iris.Constraint(time=lambda cell: cell.point.month == 1 or cell.point.month == 7))
ndata=h.data
# Convert each lat:lon position to a geohash
#ghl=[]
#for lat in h.coord('latitude').points:
#        for lon in h.coord('longitude').points:
#            ghl.append(geohash2.encode(lat, lon, precision=5))
# Reshape the HadCRUT4 data from lat:lon into a single location coord
#s=h.data.shape
#ndata=h.data.reshape((s[0],s[1]*s[2]))
# Sort the location coords alphabetically by geohash
#  Should produce a 1d-array with 2d-close locations close in the 1d.
#for t in range(s[0]):
#    ndata[t,:]=[x for _,x in sorted(zip(ghl,ndata[t,:]))]

# Plot the resulting array as a 2d colourmap
fig=Figure(figsize=(8,2),              # Width, Height (inches)
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
#ax.add_patch(Rectangle((0,0),1,1,facecolor=(0.88,0.88,0.88,1),fill=True,zorder=1))

# Nomalise by latitude
s=ndata.shape
for lat in range(s[1]):
   qn=qcut(ndata[:,lat],100,labels=False,duplicates='drop')
   ndata[:,lat]=qn

ndata=numpy.transpose(ndata)
#s=ndata.shape
#ndata=qcut(ndata.flatten(),200,labels=False,
#                             duplicates='drop').reshape(s),
y = numpy.linspace(0,1,s[0])
x = numpy.linspace(0,1,s[1])
img = ax.pcolorfast(x,numpy.flip(y),ndata,
                        cmap='magma',
                        alpha=1.0,
                        zorder=100)

fig.savefig('20CR.png')
#RdYlBu_r
