#!/usr/bin/env python

# Ocean-centred projection. Equirectangular, but inspired by Spilhaus.
# Meto global data.
# Vertical orientation

import os
import datetime

import IRData.opfc as opfc
import iris
import numpy

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib.lines import Line2D
import cartopy
import cartopy.crs as ccrs

from pandas import qcut

import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--year", help="Year",
                    type=int,required=True)
parser.add_argument("--month", help="Integer month",
                    type=int,required=True)
parser.add_argument("--day", help="Day of month",
                    type=int,required=True)
parser.add_argument("--hour", help="Time of day (0 to 23.99)",
                    type=float,required=True)
parser.add_argument("--opdir", help="Directory for output files",
                    default="%s/images/spilhaus_video" % \
                                           os.getenv('SCRATCH'),
                    type=str,required=False)
args = parser.parse_args()
if not os.path.isdir(args.opdir):
    os.makedirs(args.opdir)

dte=datetime.datetime(args.year,args.month,args.day,
                      int(args.hour),int(args.hour%1*60))


# Scale down the latitudinal variation in temperature
def damp_lat(sst,factor=0.5):
    s=sst.shape
    mt=numpy.min(sst.data)
    for lat_i in range(s[0]):
        lmt=numpy.mean(sst.data[lat_i,:])
        if numpy.isfinite(lmt):
            sst.data[lat_i,:] -= (lmt-mt)*factor
    return(sst)

# Load the Meto data - interpolate between daily updates
dte1=datetime.datetime(args.year,args.month,args.day)
sst=opfc.load('tsurf',dte1,model='global')
icec=opfc.load('icec',dte1,model='global')
orog=opfc.load('orog',dte1,model='global')
mask=opfc.load('lsmask',dte1,model='global')
dte2=datetime.datetime(args.year,args.month,args.day)+datetime.timedelta(days=1)
tmp=opfc.load('tsurf',dte2,model='global')
tmp.attributes=sst.attributes
sst=iris.cube.CubeList((sst,tmp)).merge_cube()
sst=sst.interpolate([('time',dte)],iris.analysis.Linear())
tmp=opfc.load('icec',dte2,model='global')
tmp.attributes=icec.attributes
icec=iris.cube.CubeList((icec,tmp)).merge_cube()
icec=icec.interpolate([('time',dte)],iris.analysis.Linear())

# Apply the LS mask to turn tsurf into SST
sst.data[mask.data>=0.5]=numpy.nan
sst.data=numpy.ma.array(sst.data,
                        mask=mask.data>0.5)

#sst=damp_lat(sst,factor=0.25)

# Define the figure (page size, background color, resolution, ...
fig=Figure(figsize=(10.8,19.2),              # HD video
           dpi=100,
           facecolor=(0.5,0.5,0.5,1),
           edgecolor=None,
           linewidth=0.0,
           frameon=False,                # Don't draw a frame
           subplotpars=None,
           tight_layout=None)
fig.set_frameon(False) 
# Attach a canvas
canvas=FigureCanvas(fig)

# Choose a pole rotation that approximates the
# Spilhaus projection - bordered by land, ocean in the middle.
projection=ccrs.RotatedPole(pole_longitude=113.0,
                                pole_latitude=32.0,
                                central_rotated_longitude=193.0)

# To plot the fields we are going to re-grid them onto a plot cube
#  with the pole rotated to a position that approximates the
#  Spilhaus projection - bordered by land, ocean in the middle.
def plot_cube(resolution):

    extent=[-202,180,-90,90]
    pole_latitude=32.0
    pole_longitude=113.0
    npg_longitude=193.0

    cs=iris.coord_systems.RotatedGeogCS(pole_latitude,
                                        pole_longitude,
                                        npg_longitude)
    lat_values=numpy.arange(extent[2],extent[3]+resolution,resolution)
    latitude = iris.coords.DimCoord(lat_values,
                                    standard_name='latitude',
                                    units='degrees_north',
                                    coord_system=cs)
    lon_values=numpy.arange(extent[0],extent[1]+resolution,resolution)
    longitude = iris.coords.DimCoord(lon_values,
                                     standard_name='longitude',
                                     units='degrees_east',
                                     coord_system=cs)
    dummy_data = numpy.zeros((len(lat_values), len(lon_values)))
    plot_cube = iris.cube.Cube(dummy_data,
                               dim_coords_and_dims=[(latitude, 0),
                                                    (longitude, 1)])
    return plot_cube

pc=plot_cube(0.05)   

# Mask out the duplicated SST data
def strip_dups(sst,resolution=0.25):
    scale=0.25/resolution
    s=sst.shape
    sst.data.mask[0:(int(150*scale)),0:(int(100*scale))]=True
    sst.data.mask[(int(150*scale)):(int(171*scale)),0:(int(75*scale))]=True
    sst.data.mask[(int(170*scale)):(int(190*scale)),0:(int(48*scale))]=True
    sst.data.mask[(int(190*scale)):(int(200*scale)),0:(int(40*scale))]=True
    sst.data.mask[(int(200*scale)):(int(210*scale)),0:(int(30*scale))]=True
    sst.data.mask[(int(210*scale)):(int(225*scale)),0:(int(15*scale))]=True
    sst.data.mask[(int(350*scale)):(int(475*scale)),0:(int(30*scale))]=True
    sst.data.mask[(int(540*scale)):,0:(int(50*scale))]=True
    for lat_in in range(0,int(300*scale)):
        for lon_in in range(s[1]-22*int(1/resolution),s[1]):
            if sst.data.mask[lat_in,lon_in-(360*int(1/resolution))]==False:
                sst.data.mask[lat_in,lon_in]=True
    return(sst)

# Define an axes to contain the plot. In this case our axes covers
#  the whole figure
ax = fig.add_axes([0,0,1,1])
ax.set_axis_off() # Don't want surrounding x and y axis

# Lat and lon range (in rotated-pole coordinates) for plot
ax.set_ylim(180,-202)
ax.set_xlim(-90,90)
ax.set_aspect('auto')

# Plot the SST
sst = sst.regrid(pc,iris.analysis.Linear())
# Strip out the duplicated data
sst=strip_dups(sst,resolution=0.05)
# Re-map to highlight small differences
s=sst.data.shape
sst.data=numpy.ma.array(qcut(sst.data.flatten(),100,labels=False,
                             duplicates='drop').reshape(s),
                        mask=sst.data.mask)
# Plot as a colour map
lats = sst.coord('latitude').points
lons = sst.coord('longitude').points
sst_img = ax.pcolorfast(lats, lons, numpy.transpose(sst.data),
                        cmap='RdYlBu_r',
                        alpha=1.0,
                        zorder=100)

# Draw lines of latitude and longitude
for offset in (-360,0):
    for lat in range(-90,95,5):
        lwd=0.1
        if lat%10==0: lwd=0.2
        if lat==0: lwd=1
        x=[]
        y=[]
        for lon in range(-180,181,1):
            rp=iris.analysis.cartography.rotate_pole(numpy.array(lon),
                                                     numpy.array(lat), 113, 32)
            nx=rp[0]+193+offset
            if nx>180: nx -= 360
            ny=rp[1]
            if(len(x)==0 or (abs(nx-x[-1])<10 and abs(ny-y[-1])<10)):
                x.append(nx)
                y.append(ny)
            else:
                ax.add_line(Line2D(y, x, linewidth=lwd, color=(0,0,0,1),
                                   zorder=150))
                x=[]
                y=[]
        if(len(x)>1):        
            ax.add_line(Line2D(y, x, linewidth=lwd, color=(0,0,0,1),
                               zorder=150))

    for lon in range(-180,185,5):
        lwd=0.1
        if lon%10==0: lwd=0.2
        x=[]
        y=[]
        for lat in range(-90,90,1):
            rp=iris.analysis.cartography.rotate_pole(numpy.array(lon),
                                                     numpy.array(lat), 113, 32)
            nx=rp[0]+193+offset
            if nx>180: nx -= 360
            ny=rp[1]
            if(len(x)==0 or (abs(nx-x[-1])<10 and abs(ny-y[-1])<10)):
                x.append(nx)
                y.append(ny)
            else:
                ax.add_line(Line2D(y, x, linewidth=lwd, color=(0,0,0,1),
                                   zorder=150))
                x=[]
                y=[]
        if(len(x)>1):        
            ax.add_line(Line2D(y, x, linewidth=lwd, color=(0,0,0,1),
                               zorder=150))



# Plot the sea ice
icec = icec.regrid(pc,iris.analysis.Nearest())
icec_img = ax.pcolorfast(lats, lons, numpy.transpose(icec.data),
                         cmap=matplotlib.colors.ListedColormap(
                                ((0.9,0.9,0.9,0),
                                 (0.9,0.9,0.9,1))),
                         vmin=0,
                         vmax=1,
                         alpha=1,
                         zorder=200)

# Plot the orography
o_colors=[]
for h in range(100):
    shade=0.6+h/300
    o_colors.append((shade,shade,shade,1))
orog = orog.regrid(pc,iris.analysis.Linear())
mask = mask.regrid(pc,iris.analysis.Linear())
orog.data = numpy.maximum(0.0,orog.data)
orog.data = numpy.ma.array(numpy.sqrt(orog.data),
                           mask=numpy.logical_and(mask.data<0.5,numpy.logical_not(sst.data.mask)))
orog_img = ax.pcolorfast(lats, lons, numpy.transpose(orog.data),
                         cmap=matplotlib.colors.ListedColormap(o_colors),
                         zorder=500)


# Render the figure as a png
fig.savefig("%s/v_%02d%02d%02d%02d%02d.png" % (
              args.opdir,args.year,args.month,args.day,
              int(args.hour),int(args.hour%1*60)))
