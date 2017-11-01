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
day=2
hour=18
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
lat_values=numpy.arange(7.16005,-3.77995,-0.02)
#lat_values=numpy.arange(45,-45,-0.1)

latitude = iris.coords.DimCoord(lat_values,
                                standard_name='latitude',
                                units='degrees_north',
                                coord_system=cs)
lon_values=numpy.arange(354.9107,363.3107,0.02)
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
fig.set_size_inches(16, 22)

# Plot the orography as an image
img=matplotlib.pyplot.imshow(plot_orog.data,
                             interpolation='bilinear',
                             aspect='auto',
                             cmap=stgrey,
                             extent=[354.9107,363.3107,-3.77995,7.16005])

# Overplot the temperature as an image
air2m=mopd.load_simple('mogreps-uk','air.2m',year,month,day,hour,
                       realization,forecast_period,auto_fetch=True)
air2m_p = air2m.regrid(plot_cube,iris.analysis.Linear())
img_t=matplotlib.pyplot.imshow(air2m_p.data,
                               interpolation='bilinear',
                               aspect='auto',
                               cmap='RdBu',
                               alpha=0.8,
                               extent=[354.9107,363.3107,-3.77995,7.16005])

# Overplot the precipitation as an image
prate=mopd.load_simple('mogreps-uk','prate',year,month,day,hour,
                       realization,forecast_period,auto_fetch=True)
prate_p = prate.regrid(plot_cube,iris.analysis.Linear())
# Transparent where less than threshold
prate_p.data[numpy.where(prate_p.data==0)]=numpy.NaN
img_p=matplotlib.pyplot.imshow(prate_p.data,
                               interpolation='bilinear',
                               aspect='auto',
                               cmap='Greens',
                               alpha=0.8,
                               extent=[354.9107,363.3107,-3.77995,7.16005])

# Overplot the pressure as a contour plot
prmsl=mopd.load_simple('mogreps-uk','prmsl',year,month,day,hour,
                       realization,forecast_period,auto_fetch=True)
prmsl_p = prmsl.regrid(plot_cube,iris.analysis.Linear())
lats = prmsl_p.coord('latitude').points
lons = prmsl_p.coord('longitude').points
lons,lats = numpy.meshgrid(lons,lats)
CS = matplotlib.pyplot.contour(lons, lats, prmsl_p.data/100,
                               colors='black',
                               linewidths=1,
                               extent=[354.9107,363.3107,-3.77995,7.16005])
matplotlib.pyplot.clabel(CS, inline=1, fontsize=10, fmt='%d')

# Overplot the 10m wind as a vector plot
u=mopd.load_simple('mogreps-uk','uwnd.10m',year,month,day,hour,
                       realization,forecast_period,auto_fetch=True)
u_p = u.regrid(plot_cube,iris.analysis.Linear())
v=mopd.load_simple('mogreps-uk','vwnd.10m',year,month,day,hour,
                       realization,forecast_period,auto_fetch=True)
v_p = v.regrid(plot_cube,iris.analysis.Linear())
lats=numpy.arange(7.16005,-3.77995,-0.2)
lons=numpy.arange(354.9107,363.3107,0.2)
#lons,lats = numpy.meshgrid(lons,lats)
sample_points = [('latitude', lats), ('longitude', lons)]
u_i=u_p.interpolate(sample_points, iris.analysis.Linear()).data
v_i=v_p.interpolate(sample_points, iris.analysis.Linear()).data
speed = numpy.sqrt(u_i**2 + v_i**2)
#u_i = u_i/speed
#v_i = v_i/speed
qv=matplotlib.pyplot.quiver(lons,lats,u_i,v_i,
                            headwidth=1,
                            color=(0,0,0,0.5))

# Don't want axes - turn them off
matplotlib.pyplot.axis('off')
img.axes.get_xaxis().set_visible(False)
img.axes.get_yaxis().set_visible(False)

# Output as pdf
matplotlib.pyplot.savefig('mogreps_tpp.pdf', 
                          facecolor=(1, 1, 1),
                          bbox_inches='tight', pad_inches = 0,
                          dpi=300)
