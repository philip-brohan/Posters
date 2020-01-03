#!/usr/bin/env python

# Make a poster showing ISPD4.7 obs coverage.

import os
import numpy
import datetime

import iris
import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib.patches import Rectangle

import pickle

def next_month(dt0):
    dt1 = dt0.replace(day=1)
    dt2 = dt1 + datetime.timedelta(days=32)
    dt3 = dt2.replace(day=1)
    return dt3

start_year=1836
end_year = 2015

# Plot the images
fig=Figure(figsize=(16,2),              # Width, Height (inches)
           dpi=300,
           facecolor=(0.5,0.5,0.5,1),
           edgecolor=None,
           linewidth=0.0,
           frameon=False,                # Don't draw a frame
           subplotpars=None,
           tight_layout=None)
# Attach a canvas
canvas=FigureCanvas(fig)
matplotlib.rc('image',aspect='auto')

ax = fig.add_axes([0,0,1,1],facecolor='black')
ax.set_axis_off() # Don't want surrounding x and y axis

xmin=datetime.datetime(start_year,1,1,0)-datetime.timedelta(days=100)
xmax=datetime.datetime(end_year,12,13,23)+datetime.timedelta(days=250)
width=xmax-xmin
ax.set_xlim(xmin,xmax)
ymin=-90
ymax=90
height=ymax-ymin
ax.set_ylim(ymin,ymax)
ax.set_aspect('auto')

ax.add_patch(Rectangle((xmin,ymin),width,height,
                        facecolor=(0.05,0.05,0.05,1),fill=True,zorder=1))

# For each month, load and plot the observations
def y_to_j(y):
    return numpy.minimum(height-1,numpy.maximum(0, 
            numpy.floor((y-ymin)/(ymax-ymin)*(height-1)))).astype(int)

n_obs=numpy.zeros([(end_year+1-start_year)*12,180])
px=[]
for year in range(start_year,end_year+1):
    for month in range(1,13):
        m_count = (year-start_year)*12 + month-1
        px.append(datetime.datetime(year,month,15))
        fname= "%s/ISPD_poster/%04d/%02d.pkl" % (os.getenv('SCRATCH'),
                                                 year,month)
        s_ob = pickle.load( open( fname, "rb" ) )
        sdate = datetime.datetime(year,month,1,0,0)
        edate = next_month(sdate)
        n_steps = int((edate-sdate).total_seconds()/(3600*6))
        lats=numpy.array(s_ob['Latitude'])
        lat_i=y_to_j(lats)
        for i in range(len(lat_i)):
            n_obs[m_count,lat_i[i]] += 1
        n_obs[m_count,:] /= n_steps


# Plot the observations locations
s=n_obs.shape
for i in range(s[0]):
    for j in range(s[1]):
        if n_obs[i,j]==0: continue
        scale=min(1.0,max(0.05,numpy.sqrt(n_obs[i,j])))
        ax.add_patch(Rectangle((px[i],j/s[1]*height+ymin),
                               datetime.timedelta(days=31)*scale,
                               (height/180)*scale,
                               facecolor='yellow',
                               edgecolor='yellow',
                               linewidth=0.1,
                               fill=True,
                               alpha=1))

fig.savefig('ISPD.png')
