# UK Weather plot: Temperature, Pressure, and Precip, over orography

import iris
import os
import numpy
import matplotlib.pyplot
import matplotlib.colors
import mopd

# Remove incomprehensible error message
iris.FUTURE.netcdf_promote=True

# Specify the data to plot
year=2016
month=3
day=12
hour=6
forecast_period=3
realization=0

# Load the orography cube
orog=iris.load_cube("%s/orography/ETOPO2v2c_ud.nc" %
                    os.environ['SCRATCH'])
# Set land range to 0-1
orog.data[numpy.where(orog.data>=0)]=orog.data[numpy.where(orog.data>=0)]/6290
# Set all the sea areas (height<0) to missing
orog.data[numpy.where(orog.data<0)]=numpy.NaN
# Specify the coordinate dimensions
cs=iris.coord_systems.GeogCS(iris.fileformats.pp.EARTH_RADIUS)
orog.coord('latitude').coord_system=cs
orog.coord('longitude').coord_system=cs

# Make a dummy cube on the plot grid (same as mogreps-uk)
cs=iris.coord_systems.RotatedGeogCS(37.5,177.5)
lat_values=numpy.arange(7.16005,-3.77995,-0.01)
#lat_values=numpy.arange(45,-45,-0.1)

latitude = iris.coords.DimCoord(lat_values,
                                standard_name='latitude',
                                units='degrees_north',
                                coord_system=cs)
lon_values=numpy.arange(354.9107,363.3107,0.01)
#lon_values=numpy.arange(-45,45,0.1)
longitude = iris.coords.DimCoord(lon_values,
                                standard_name='longitude',
                                units='degrees_east',
                                coord_system=cs)
dummy_data = numpy.zeros((len(lat_values), len(lon_values)))
plot_cube = iris.cube.Cube(dummy_data, 
                           dim_coords_and_dims=[(latitude, 0),
                                                (longitude, 1)])

# Regrid the orography onto the plot cube
plot_orog=orog.regrid(plot_cube,iris.analysis.Linear())

# Make a colour sequence
cdict = {'red':   [(0.0,  0.0, 0.0,),
                   (1.0,  0.0, 0.0)],

         'green': [(0.0,  0.0, 0.0),
                   (1.0,  0.0, 0.0)],

         'blue':  [(0.0,  0.0, 0.0),
                   (1.0,  0.0, 0.0)],

         'alpha': [(0.0,  0.2, 0.2),
                   (1.0,  1.0, 1.0)]}
stgrey = matplotlib.colors.LinearSegmentedColormap('stgrey',cdict,256)

# Now make the plot
fig=matplotlib.pyplot.figure()

# A4 size
fig.set_size_inches(8, 11)

# Plot the orography as an image
img=matplotlib.pyplot.imshow(plot_orog.data,
                             interpolation='bilinear',
                             aspect='auto',
                             cmap=stgrey)

# Overplot the pressure as a contour plot
prmsl=mopd.load_simple('mogreps-uk','prmsl',year,month,day,hour,
                       realization,forecast_period)
prmsl_p = prmsl.regrid(plot_cube,iris.analysis.Linear())
lats = prmsl_p.coord('latitude').points
lons = prmsl_p.coord('longitude').points
lons,lats = numpy.meshgrid(lons,lats)
CS = matplotlib.pyplot.contour(lons, lats, prmsl_p.data)

# Don't want axes - turn them off
matplotlib.pyplot.axis('off')
img.axes.get_xaxis().set_visible(False)
img.axes.get_yaxis().set_visible(False)

# Output as pdf
matplotlib.pyplot.savefig('mogreps_tpp.pdf', 
                          facecolor=(1, 1, 1),
                          bbox_inches='tight', pad_inches = 0)
