#!/usr/bin/env python

# Atmospheric state with the equator as a border.

import Meteorographica as mg
import iris
import numpy

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib.patches import CirclePolygon
from matplotlib.patches import Circle
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
t2m=damp_lat(t2m,factor=0.4)
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


# To plot the fields we are going to re-grid them onto a plot cube on
#  modified Cassini projection: poles in Indian and Pacific oceans, plot
#  border is the equator.
pole_latitude=0.0
pole_longitude=60.0
npg_longitude=270.0
cs=iris.coord_systems.RotatedGeogCS(pole_latitude,
                                    pole_longitude,
                                    npg_longitude)


def plot_cube(resolution):

    extent=[-180,180,-90,90]
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
t2m.data=numpy.ma.array(qcut(t2m.data.flatten(),100,labels=False,
                             duplicates='drop').reshape(s),
                        mask=t2m.data.mask)
# Plot as a colour map
lats = t2m.coord('latitude').points
lons = t2m.coord('longitude').points
sst_img = ax.pcolorfast(lons, lats, t2m.data,
                        cmap='coolwarm',
                        alpha=1.0,
                        vmin=0,
                        vmax=102,
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

# Plot the wind
rw=iris.analysis.cartography.rotate_winds(u10m,v10m,cs)
u10m = rw[0].regrid(pc,iris.analysis.Linear())
v10m = rw[1].regrid(pc,iris.analysis.Linear())

u_interpolator = iris.analysis.Linear().interpolator(u10m, 
                                    ['latitude', 'longitude'])
v_interpolator = iris.analysis.Linear().interpolator(v10m, 
                                    ['latitude', 'longitude'])

# Generate a set of points to plot at
w_points=mg.wind.allocate_vector_points(scale=0.5,max_points=1000000)#,
#                                        lat_range=(-45,45),lon_range=(75,165))
w_lats = w_points['Latitude']
w_lons = w_points['Longitude']
u_i=numpy.zeros(w_lons.size)
v_i=numpy.zeros(w_lons.size)
for i in range(w_lons.size):
    u_i[i]=u_interpolator([w_lats[i],w_lons[i]]).data*-1
    v_i[i]=v_interpolator([w_lats[i],w_lons[i]]).data*-1
qv=ax.quiver(w_lons,w_lats,u_i,v_i,
                        headwidth=1,
                        minlength=0.1,
                        color=(0,0,0,0.5),
                        scale=4000,
                        zorder=400)
 

# Render the figure as a png
fig.savefig('wind_points.png')
