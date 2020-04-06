#!/usr/bin/env python

# Plot temperature and observations from EUSTACE
# Video version.

import os
import sys
import datetime

import iris
import numpy

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure
from matplotlib.patches import Rectangle
from matplotlib.lines import Line2D

sys.path.append('%s/../load/' % os.path.dirname(__file__))

from load import EUSTACE_ensemble_for_day
from load import EUSTACE_average_for_day
from load import EUSTACE_uncertainty_for_day
from load import EUSTACE_obs_influence_for_day
from load import EUSTACE_normals
from load import EUSTACE_sds
from load import EUSTACE_stations_for_day
from load import ICOADS_for_day

import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--year", help="Year",
                    type=int,required=True)
parser.add_argument("--month", help="Integer month",
                    type=int,required=True)
parser.add_argument("--day", help="Day of month",
                    type=int,required=True)
parser.add_argument("--opdir", help="Directory for output files",
                    default="%s/images/EUSTACE_video" % \
                                           os.getenv('SCRATCH'),
                    type=str,required=False)
args = parser.parse_args()
if not os.path.isdir(args.opdir):
    os.makedirs(args.opdir)

target = datetime.date(args.year,args.month,args.day)

# Fix dask SPICE bug
import dask
dask.config.set(scheduler='single-threaded')

# Geometry for plotting
def plot_cube(resolution,xmin=-180,xmax=180,
                         ymin=-90,ymax=90,
                         pole_latitude=90,
                         pole_longitude=180,
                         npg_longitude=0):

    cs=iris.coord_systems.RotatedGeogCS(pole_latitude,
                                        pole_longitude,
                                        npg_longitude)
    lat_values=numpy.arange(ymin,ymax+resolution,resolution)
    latitude = iris.coords.DimCoord(lat_values,
                                    standard_name='latitude',
                                    units='degrees_north',
                                    coord_system=cs)
    lon_values=numpy.arange(xmin,xmax+resolution,resolution)
    longitude = iris.coords.DimCoord(lon_values,
                                     standard_name='longitude',
                                     units='degrees_east',
                                     coord_system=cs)
    dummy_data = numpy.zeros((len(lat_values), len(lon_values)))
    plot_cube = iris.cube.Cube(dummy_data,
                               dim_coords_and_dims=[(latitude, 0),
                                                    (longitude, 1)])
    return plot_cube

cplot=plot_cube(0.2) 

# Define the figure (page size, background color, resolution, ...
fig=Figure(figsize=(19.2,10.8),              # Width, Height (inches)
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
# Only one thing in this figure
ax = fig.add_axes([0,0,1,1])
ax.set_axis_off()
ax.set_xlim(-180,180)
ax.set_ylim(-90,90)
ax.set_aspect('auto')
# Background
ax.add_patch(Rectangle((-180,-90),360,180,
                       facecolor=(0.5,0.5,0.5,1),
                       fill=True,zorder=1))

# Land-sea mask
mask=iris.load_cube("%s/fixed_fields/land_mask/opfc_global_2019.nc" % 
                                                  os.getenv('DATADIR'))
mask = mask.regrid(cplot,iris.analysis.Linear())
lats = mask.coord('latitude').points
lons = mask.coord('longitude').points
mask_img = ax.pcolorfast(lons, lats, mask.data,
                         cmap=matplotlib.colors.ListedColormap(
                                ((0.0,0.0,0.0,0),
                                 (0.0,0.0,0.0,1))),
                         vmin=0,
                         vmax=1,
                         alpha=0.15,
                         zorder=120)

# Normalise a T2m field so it is approximately uniformly distributed
#  over the range 0-1 (when projected in a conventional equirectangular
#  projection). (If you then plot a colour map of the normalised data,
#  there will be an approximately equal amount of each colour).
# Takes an iris cube as input and returns one as output
def quantile_normalise_t2m(p):
   res=p.copy()
   res.data[res.data>300.10]=0.95
   res.data[res.data>299.9]=0.90
   res.data[res.data>298.9]=0.85
   res.data[res.data>297.5]=0.80
   res.data[res.data>295.7]=0.75
   res.data[res.data>293.5]=0.70
   res.data[res.data>290.1]=0.65
   res.data[res.data>287.6]=0.60
   res.data[res.data>283.7]=0.55
   res.data[res.data>280.2]=0.50
   res.data[res.data>277.2]=0.45
   res.data[res.data>274.4]=0.40
   res.data[res.data>272.3]=0.35
   res.data[res.data>268.3]=0.30
   res.data[res.data>261.4]=0.25
   res.data[res.data>254.6]=0.20
   res.data[res.data>249.1]=0.15
   res.data[res.data>244.9]=0.10
   res.data[res.data>240.5]=0.05
   res.data[res.data>0.95]=0.0
   return res

# Temperature normals
normal=EUSTACE_normals(args.month,args.day)
sd=EUSTACE_sds(args.month,args.day)

# Temperature analysis
analysis_m = EUSTACE_average_for_day(args.year,args.month,args.day)
pday = target-datetime.timedelta(days=1)
analysis_m += EUSTACE_average_for_day(pday.year,pday.month,pday.day)*0.5
pday = target+datetime.timedelta(days=1)
analysis_m += EUSTACE_average_for_day(pday.year,pday.month,pday.day)*0.5
analysis_m /= 2
# Compromise between actuals and anomalies
analysis_m += analysis_m-normal
analysis_n = quantile_normalise_t2m(analysis_m)

# Smooth the obs influence - it's undersampled
analysis_o = EUSTACE_obs_influence_for_day(args.year,args.month,args.day)
#pday = target-datetime.timedelta(days=2)
#analysis_o += EUSTACE_obs_influence_for_day(pday.year,pday.month,pday.day)*0.25
pday = target-datetime.timedelta(days=1)
analysis_o += EUSTACE_obs_influence_for_day(pday.year,pday.month,pday.day)*0.5
pday = target+datetime.timedelta(days=1)
analysis_o += EUSTACE_obs_influence_for_day(pday.year,pday.month,pday.day)*0.5
#pday = target+datetime.timedelta(days=2)
#analysis_o += EUSTACE_obs_influence_for_day(pday.year,pday.month,pday.day)*0.25
analysis_o /= 2

analysis_n = analysis_n.regrid(cplot,iris.analysis.Linear())
analysis_o = analysis_o.regrid(cplot,iris.analysis.Linear())
lats = analysis_n.coord('latitude').points
lons = analysis_n.coord('longitude').points
for a in range(100):
    alpha = (a+1)/100
    analysis_p = analysis_n.copy()
    analysis_p.data.mask[analysis_o.data <= (alpha-0.01)] = True
    analysis_p.data.mask[analysis_o.data > alpha] = True
    t2m_img = ax.pcolorfast(lons, lats, analysis_p.data,
                            cmap='RdYlBu_r',
                            alpha=alpha,
                            vmin=0,
                            vmax=1,
                            zorder=100)

width=360
height=180
xmin=-180
xmax=180
ymin=-90
ymax=90
def x_to_i(x):
    return numpy.minimum(width-1,numpy.maximum(0, 
            numpy.floor((x-xmin)/(xmax-xmin)*(width-1)))).astype(int)
def y_to_j(y):
    return numpy.minimum(height-1,numpy.maximum(0, 
            numpy.floor((y-ymin)/(ymax-ymin)*(height-1)))).astype(int)
def i_to_x(i):
    return xmin + ((i+1)/width) * (xmax-xmin)
def j_to_y(j):
    return ymin + ((j+1)/height) * (ymax-ymin)
def get_obs(year,month,day):
    # station obs
    st_obs = EUSTACE_stations_for_day(year,month,day)
    # ship obs
    sh_obs = ICOADS_for_day(year,month,day)
    # Reduce the obs to 1-degree mean pseudo-obs
    obs = numpy.ma.array(numpy.zeros([width,height]), mask = True)
    counts = numpy.zeros([width,height])
    lon_i=x_to_i(st_obs['longitude'])
    lat_i=y_to_j(st_obs['latitude'])
    for i in range(len(lon_i)):
        obs.mask[lon_i[i],lat_i[i]]=False
        obs[lon_i[i],lat_i[i]] += (st_obs['tasmin'][i]+st_obs['tasmax'][i])/2
        counts[lon_i[i],lat_i[i]] += 1
    lon_i=x_to_i(sh_obs['longitude'])
    lat_i=y_to_j(sh_obs['latitude'])
    for i in range(len(lon_i)):
        obs.mask[lon_i[i],lat_i[i]]=False
        obs[lon_i[i],lat_i[i]] += sh_obs['AT'][i]
        counts[lon_i[i],lat_i[i]] += 1

    obs /= counts
    return(obs)

# Plot the observations locations
def plot_obs(obs,alpha):
    for i in range(width):
        for j in range(height):
            if obs.mask[i,j]: continue
            rp=iris.analysis.cartography.rotate_pole(numpy.array(i_to_x(i)),
                                                     numpy.array(j_to_y(j)),
                                                     180,
                                                     90)
            nlon=rp[0][0]
            nlat=rp[1][0]
            ax.add_patch(matplotlib.patches.Circle((nlon,nlat),
                                                    radius=0.2,
                                                    facecolor='black',
                                                    edgecolor='black',
                                                    linewidth=0.1,
                                                    alpha=alpha,
                                                    zorder=180))
    
# Plot obs from a few days around the target, for a smooth video
pday = target-datetime.timedelta(days=2)
plot_obs(get_obs(pday.year,pday.month,pday.day),0.25)
pday = target-datetime.timedelta(days=1)
plot_obs(get_obs(pday.year,pday.month,pday.day),0.5)
pday = target
plot_obs(get_obs(pday.year,pday.month,pday.day),1)
pday = target+datetime.timedelta(days=1)
plot_obs(get_obs(pday.year,pday.month,pday.day),0.5)
pday = target+datetime.timedelta(days=2)
plot_obs(get_obs(pday.year,pday.month,pday.day),0.25)


# Label with the date
ax.text(177.5,
         88,
         "%04d-%02d-%02d" % (args.year,args.month,args.day),
         horizontalalignment='right',
         verticalalignment='top',
         color='black',
         bbox=dict(facecolor=(0.6,0.6,0.6,0.5),
                   edgecolor='black',
                   boxstyle='round',
                   pad=0.5),
         size=14,
         clip_on=True,
         zorder=500)

# Render the figure as a png
fig.savefig('%s/%04d%02d%02d00.png' % (args.opdir,args.year,
                                     args.month,args.day))
