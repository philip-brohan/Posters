#!/usr/bin/env python

# Atmospheric state with the equator as a border.

import Meteorographica as mg
import iris
import numpy

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
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

# Load the ERA5 T2M
t2m=iris.load_cube('ERA5_t2m_2019031206.nc')
# Get rid of the (1-member) time dimension
t2m=t2m.collapsed('time', iris.analysis.MEAN)
coord_s=iris.coord_systems.GeogCS(iris.fileformats.pp.EARTH_RADIUS)
t2m.coord('latitude').coord_system=coord_s
t2m.coord('longitude').coord_system=coord_s
t2m=damp_lat(t2m,factor=0.01)
# And the precipitation
precip=iris.load_cube('ERA5_precip_2019031206.nc')
precip=precip.collapsed('time', iris.analysis.MEAN)
precip.coord('latitude').coord_system=coord_s
precip.coord('longitude').coord_system=coord_s
# And the 10m wind
u10m=iris.load_cube('ERA5_u10m_2019031206.nc')
u10m=u10m.collapsed('time', iris.analysis.MEAN)
u10m.coord('latitude').coord_system=coord_s
u10m.coord('longitude').coord_system=coord_s
v10m=iris.load_cube('ERA5_v10m_2019031206.nc')
v10m=v10m.collapsed('time', iris.analysis.MEAN)
v10m.coord('latitude').coord_system=coord_s
v10m.coord('longitude').coord_system=coord_s
# And the land-sea mask
mask=iris.load_cube('ERA5_ls_mask.nc')
mask=mask.collapsed('time', iris.analysis.MEAN)
mask.coord('latitude').coord_system=coord_s
mask.coord('longitude').coord_system=coord_s


# Define the figure (page size, background color, resolution, ...
aspect=16/9.0
fig=Figure(figsize=(22,22/aspect),              # Width, Height (inches)
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


# To plot the fields we are going to re-grid them onto a plot cube on
#  modified Cassini projection: poles in Indian and Pacific oceans, plot
#  border is the equator.
extent=[-180,180,-90,90]
pole_latitude=90.0
pole_longitude=180.0
npg_longitude=0.0
#pole_latitude=0.0
#pole_longitude=60.0
#npg_longitude=270.0
cs=iris.coord_systems.RotatedGeogCS(pole_latitude,
                                    pole_longitude,
                                    npg_longitude)

def plot_cube(resolution):

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
    dummy_data = numpy.zeros((len(lon_values), len(lat_values)))
    plot_cube = iris.cube.Cube(dummy_data,
                               dim_coords_and_dims=[(longitude, 0),
                                                    (latitude, 1)])
    return plot_cube

pc=plot_cube(0.1)   


# Make the wind noise
def wind_field(uw,vw,iterations=50,epsilon=0.003,sscale=1):
    # Random field as the source of the distortions
    z=uw.copy()
    (width,height)=z.data.shape
    z.data=numpy.random.rand(width,height)-0.5
    # Each point in this field has an index location (i,j)
    #  and a real (x,y) position
    xmin=numpy.min(uw.coords()[0].points)
    xmax=numpy.max(uw.coords()[0].points)
    ymin=numpy.min(uw.coords()[1].points)
    ymax=numpy.max(uw.coords()[1].points)
    # Convert between index and real positions
    def i_to_x(i):
        return xmin + (i/width) * (xmax-xmin)
    def j_to_y(j):
        return ymin + (j/height) * (ymax-ymin)
    def x_to_i(x):
        return numpy.minimum(width-1,numpy.maximum(0, 
                numpy.floor((x-xmin)/(xmax-xmin)*(width-1)))).astype(int)
    def y_to_j(y):
        return numpy.minimum(height-1,numpy.maximum(0, 
                numpy.floor((y-ymin)/(ymax-ymin)*(height-1)))).astype(int)
    i,j=numpy.mgrid[0:width,0:height]
    x=i_to_x(i)
    y=j_to_y(j)
    # Result is a distorted version of the random field
    result=z.copy()
    # Repeatedly, move the x,y points according to the vector field
    #  and update result with the random field at their locations
    ss=uw.copy()
    ss.data=numpy.sqrt(uw.data**2+vw.data**2)
    for k in range(iterations):
        x += epsilon*uw.data
        x[x>xmax]=x[x>xmax]-xmax+xmin
        x[x<xmin]=x[x<xmin]-xmin+xmax
        y += epsilon*vw.data
        y[y>ymax]=y[y>ymax]-ymax+ymin
        y[y<ymin]=y[y<ymin]-ymin+ymax
        i=x_to_i(x)
        j=y_to_j(y)
        result.data += z.data[i,j]*ss.data[i,j]/sscale
    return result

rw=iris.analysis.cartography.rotate_winds(u10m,v10m,cs)
u10m = rw[0].regrid(pc,iris.analysis.Linear())
u10m.transpose()
v10m = rw[1].regrid(pc,iris.analysis.Linear())
v10m.transpose()
wind_noise_field=wind_field(u10m,v10m,epsilon=0.003)
wind_noise_field.transpose()

# Define an axes to contain the plot. In this case our axes covers
#  the whole figure
ax = fig.add_axes([0,0,1,1])
ax.set_axis_off() # Don't want surrounding x and y axis

# Lat and lon range (in rotated-pole coordinates) for plot
ax.set_xlim(-180,180)
ax.set_ylim(-90,90)
ax.set_aspect('auto')

# Plot the T2M
t2m = t2m.regrid(pc,iris.analysis.Linear())
# Re-map to highlight small differences
s=t2m.data.shape
t2m.data=numpy.ma.array(qcut(t2m.data.flatten(),1000,labels=False,
                             duplicates='drop').reshape(s),
                        mask=t2m.data.mask)
# Adjust to show the wind
wscale=200
wind_noise_field.data=qcut(wind_noise_field.data.flatten(),wscale,labels=False,
                             duplicates='drop').reshape(s)-(wscale-1)/2

# Plot as a colour map
lats = t2m.coord('latitude').points
lons = t2m.coord('longitude').points
sst_img = ax.pcolorfast(lons, lats, t2m.data+wind_noise_field.data,
                        cmap='RdYlBu_r',
                        alpha=1.0,
                        zorder=100)


# Plot the land mask
mask = mask.regrid(pc,iris.analysis.Linear())
mask_img = ax.pcolorfast(lons, lats, mask.data,
                         cmap=matplotlib.colors.ListedColormap(
                                ((0.6,0.6,0.6,0),
                                 (0.6,0.6,0.6,1))),
                         vmin=0,
                         vmax=1,
                         alpha=0.5,
                         zorder=200)

#i=u10m.coord('longitude').points
#j=u10m.coord('latitude').points
#img = ax.pcolorfast(i, j, wind_noise_field.data,
#                        cmap='Greys',
#                        alpha=0.5,
#                        zorder=300)



# Render the figure as a png
fig.savefig('wind_noise.png')
