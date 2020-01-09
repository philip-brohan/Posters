#!/usr/bin/env python

# Ocean-centred projection. Equirectangular, but inspired by Spilhaus.

import Meteorographica as mg
import iris
import numpy

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
import cartopy
import cartopy.crs as ccrs

from pandas import qcut

# Load the ERA5 SST
sst=iris.load_cube('ERA5_sst_2019031206.nc')
# Get rid of the (1-member) time dimension
sst=sst.collapsed('time', iris.analysis.MEAN)
coord_s=iris.coord_systems.GeogCS(iris.fileformats.pp.EARTH_RADIUS)
sst.coord('latitude').coord_system=coord_s
sst.coord('longitude').coord_system=coord_s
# And the sea-ice
icec=iris.load_cube('ERA5_icec_2019031206.nc')
icec=icec.collapsed('time', iris.analysis.MEAN)
icec.coord('latitude').coord_system=coord_s
icec.coord('longitude').coord_system=coord_s


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

# Lat:Lon aspect does not match the plot aspect, ignore this and
#  fill the figure with the plot.
matplotlib.rc('image',aspect='auto')

# All mg plots use Rotated Pole: choose a rotation that approximates the
# Spilhaus projection - bordered by land, ocean in the middle.
projection=ccrs.RotatedPole(pole_longitude=113.0,
                                pole_latitude=32.0,
                                central_rotated_longitude=193.0)

# Define an axes to contain the plot. In this case our axes covers
#  the whole figure
ax = fig.add_axes([22/(360+22),0,360/(360+22),1],projection=projection)
ax.set_axis_off() # Don't want surrounding x and y axis
# Set the axes background colour
ax.background_patch.set_facecolor((0.5,0.5,0.5,1))

# Lat and lon range (in rotated-pole coordinates) for plot
extent=[0.0,180.0,-90.0,90.0]
ax.set_extent(extent, crs=projection)
ax.set_xlim([-180, 180])

# Plot the SST
plot_cube=mg.utils.dummy_cube(ax,0.05)
sst = sst.regrid(plot_cube,iris.analysis.Linear())
# Re-map to highlight small differences
s=sst.data.shape
sst.data=numpy.ma.array(qcut(sst.data.flatten(),200,labels=False,
                             duplicates='drop').reshape(s),
                        mask=sst.data.mask)
# Plot as a colour map
lats = sst.coord('latitude').points
lons = sst.coord('longitude').points
sst_img = ax.pcolorfast(lons, lats, sst.data,
                        cmap='RdYlBu_r',
                        alpha=1.0,
                        zorder=100)

# Plot the sea ice
icec = icec.regrid(plot_cube,iris.analysis.Linear())
icec_img = ax.pcolorfast(lons, lats, icec.data,
                         cmap=matplotlib.colors.ListedColormap(
                                ((0.9,0.9,0.9,0),
                                 (0.88,0.88,0.88,1),
                                 (0.86,0.86,0.86,1),
                                 (0.84,0.84,0.84,1),
                                 (0.82,0.82,0.82,1),
                                 (0.8,0.8,0.8,1))),
                         vmin=0,
                         vmax=1,
                         alpha=1,
                         zorder=200)

# Draw a lat:lon grid
#mg.background.add_grid(ax,
#                       sep_major=5,
#                       sep_minor=2.5,
#                       color=(0,0.3,0,0.2))


# Add the land
land_img = ax.background_img(name='GreyT', resolution='low')


# Subsidiary axes to allow more than -180:180 as range
ax2 = fig.add_axes([0,0,22/(360+22),1],projection=projection)
ax2.set_axis_off() # Don't want surrounding x and y axis
# Set the axes background colour
ax2.background_patch.set_facecolor((0.5,0.5,0.5,1))

# Lat and lon range (in rotated-pole coordinates) for plot
extent2=[158,180.0,-90.0,90.0]
ax2.set_extent(extent2, crs=projection)
ax2.set_xlim([158, 180])

sst_img = ax2.pcolorfast(lons, lats, sst.data,
                         cmap='RdYlBu_r',
                         alpha=1.0,
                         zorder=100)

icec_img = ax2.pcolorfast(lons, lats, icec.data,
                          cmap=matplotlib.colors.ListedColormap(
                                 ((0.9,0.9,0.9,0),
                                  (0.9,0.9,0.9,1))),
                          vmin=0,
                          vmax=1,
                          alpha=1,
                          zorder=200)

# Draw a lat:lon grid
#mg.background.add_grid(ax,
#                       sep_major=5,
#                       sep_minor=2.5,
#                       color=(0,0.3,0,0.2))


# Add the land
land_img = ax2.background_img(name='GreyT', resolution='low')


# Render the figure as a png
fig.savefig('sst.png')
