#!/usr/bin/env python

# Ocean-centred projection. Equirectangular, but inspired by Spilhaus.
# ERA5 data only

import Meteorographica as mg
import iris
import numpy

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib.lines import Line2D
import cartopy
import cartopy.crs as ccrs

from pandas import qcut

# Scale down the latitudinal variation in temperature
def damp_lat(sst,factor=0.5):
    s=sst.shape
    mt=numpy.min(sst.data)
    for lat_i in range(s[0]):
        lmt=numpy.mean(sst.data[lat_i,:])
        if numpy.isfinite(lmt):
            sst.data[lat_i,:] -= (lmt-mt)*factor
    return(sst)

# Load the ERA5 SST
sst=iris.load_cube('ERA5_sst_2019031206.nc')
# Get rid of the (1-member) time dimension
sst=sst.collapsed('time', iris.analysis.MEAN)
coord_s=iris.coord_systems.GeogCS(iris.fileformats.pp.EARTH_RADIUS)
sst.coord('latitude').coord_system=coord_s
sst.coord('longitude').coord_system=coord_s
sst=damp_lat(sst,factor=0.25)
# And the sea-ice
icec=iris.load_cube('ERA5_icec_2019031206.nc')
icec=icec.collapsed('time', iris.analysis.MEAN)
icec.coord('latitude').coord_system=coord_s
icec.coord('longitude').coord_system=coord_s
# And the orography
orog=iris.load_cube('ERA5_orography.nc')
orog=orog.collapsed('time', iris.analysis.MEAN)
orog.coord('latitude').coord_system=coord_s
orog.coord('longitude').coord_system=coord_s
# And the land-sea mask
mask=iris.load_cube('ERA5_ls_mask.nc')
mask.coord('latitude').coord_system=coord_s
mask.coord('longitude').coord_system=coord_s


# Define the figure (page size, background color, resolution, ...
fig=Figure(figsize=(48.8,33.1),              # Width, Height (inches)
           dpi=300,
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

pc=plot_cube(0.25)   

# Mask out the duplicated SST data
#  Resolution specific (for 0.25 degree rotated cube).
def strip_dups(sst):
    s=sst.shape
    sst.data.mask[0:150,0:100]=True
    sst.data.mask[150:171,0:75]=True
    sst.data.mask[170:190,0:48]=True
    sst.data.mask[190:200,0:40]=True
    sst.data.mask[200:210,0:30]=True
    sst.data.mask[210:225,0:15]=True
    sst.data.mask[350:475,0:30]=True
    sst.data.mask[540:,0:50]=True
    for lat_in in range(0,300):
        for lon_in in range(s[1]-22*4,s[1]):
            if sst.data.mask[lat_in,lon_in-(360*4)]==False:
                sst.data.mask[lat_in,lon_in]=True
    return(sst)

# Define an axes to contain the plot. In this case our axes covers
#  the whole figure
ax = fig.add_axes([0,0,1,1])
ax.set_axis_off() # Don't want surrounding x and y axis

# Lat and lon range (in rotated-pole coordinates) for plot
ax.set_xlim(-202,180)
ax.set_ylim(-90,90)
ax.set_aspect('auto')

# Plot the SST
sst = sst.regrid(pc,iris.analysis.Linear())
# Strip out the duplicated data
sst=strip_dups(sst)
# Re-map to highlight small differences
s=sst.data.shape
sst.data=numpy.ma.array(qcut(sst.data.flatten(),100,labels=False,
                             duplicates='drop').reshape(s),
                        mask=sst.data.mask)
# Plot as a colour map
lats = sst.coord('latitude').points
lons = sst.coord('longitude').points
sst_img = ax.pcolorfast(lons, lats, sst.data,
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
                ax.add_line(Line2D(x, y, linewidth=lwd, color=(0,0,0,1),
                                   zorder=150))
                x=[]
                y=[]
        if(len(x)>1):        
            ax.add_line(Line2D(x, y, linewidth=lwd, color=(0,0,0,1),
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
                ax.add_line(Line2D(x, y, linewidth=lwd, color=(0,0,0,1),
                                   zorder=150))
                x=[]
                y=[]
        if(len(x)>1):        
            ax.add_line(Line2D(x, y, linewidth=lwd, color=(0,0,0,1),
                               zorder=150))



# Plot the sea ice
icec = icec.regrid(pc,iris.analysis.Nearest())
icec_img = ax.pcolorfast(lons, lats, icec.data,
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
orog_img = ax.pcolorfast(lons, lats, orog.data,
                         cmap=matplotlib.colors.ListedColormap(o_colors),
                         zorder=500)


# Render the figure as a png
fig.savefig('one_axes.png')
