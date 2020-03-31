# Library functions to load EUSTACE and ICOADS data
#  from the netCDF files

import os
import iris
import numpy
from netCDF4 import Dataset
from time import strptime

EUSTACE_base_dir = "%s/EUSTACE" % os.getenv('SCRATCH')
ICOADS_base_dir  = "%s/ICOADS3" % os.getenv('SCRATCH')

def EUSTACE_ensemble_for_day(year,month,day):
    e=[]
    for member in range(10):
         f=iris.load_cube('%s/1.0/%04d/tas_global_eustace_0_%04d%02d%02d.nc' %
                             (EUSTACE_base_dir,year,year,month,day),
                             iris.Constraint(cube_func=(lambda cell: \
                              cell.var_name == 'tasensemble_%d' % member)))
         f=f.collapsed('time', iris.analysis.MEAN)
         f.attributes=None
         f.var_name='tasensemble'
         f.add_aux_coord(iris.coords.AuxCoord(member, long_name='member'))      
         e.append(f)
    e=iris.cube.CubeList(e).merge_cube()
    return(e)

def EUSTACE_stations_for_day(year,month,day):
    fn = "%s/stations/eustace_stations_global_%04d_daily_temperature.nc" % (
           EUSTACE_base_dir,year)
    day_of_year = strptime("%04d.%02d.%02d" % (year,month,day), 
                           "%Y.%m.%d").tm_yday
    nc_fid = Dataset(fn, 'r')
    latitude = nc_fid.variables['latitude'][:] 
    longitude = nc_fid.variables['longitude'][:] 
    tasmax = nc_fid.variables['tasmax'][day_of_year-1,:]
    tasmin = nc_fid.variables['tasmin'][day_of_year-1,:]
    ismasked = (latitude.mask+longitude.mask+
                tasmax.mask+tasmin.mask)
    return {'tasmax':tasmax[~ismasked],
            'tasmin':tasmin[~ismasked],
            'latitude':latitude[~ismasked],
            'longitude':longitude[~ismasked]}

def ICOADS_for_day(year,month,day):
    fn = "%s/netCDF/ICOADS_R3.0.0_%04d-%02d.nc" % (
           ICOADS_base_dir,year,month)
    nc_fid = Dataset(fn, 'r')
    dtbase = datetime.datetime(1662,10,15,12)
    dts = [dtbase+datetime.timedelta(days=x) \
             for x in nc_fid.variables['time'][:]]
    dtdays = numpy.array([x.day==day for x in dts])
    latitude = nc_fid.variables['lat'][dtdays]
    longitude = nc_fid.variables['lon'][dtdays]
    AT = nc_fid.variables['AT'][dtdays]
    ismasked = (latitude.mask+longitude.mask+
                AT.mask)
    return {'AT':AT[~ismasked],
            'latitude':latitude[~ismasked],
            'longitude':longitude[~ismasked]}
