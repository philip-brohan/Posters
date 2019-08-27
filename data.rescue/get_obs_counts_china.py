# Find times where there are new observations in the China region

import datetime
import virtualtime
import os
import os.path
import pandas


# List of years to look in
years=(1872,1880,1883,1887,1894,1902,1909,1917,1924,1931,1939,1946,
       1953,1961,1968,1975,1983,1990,1997,2005,2012)

# Local version for obs retrieval
def get_data_dir(version):
    """Return the root directory containing 20CR netCDF files"""
    g="%s/20CR/version_%s/" % (os.environ['SCRATCH'],version)
    if os.path.isdir(g):
        return g
    g="/project/projectdirs/m958/netCDF.data/20CR_v%s/" % version
    if os.path.isdir(g):
        return g
    raise IOError("No data found for version %s" % version)

def get_data_file_name(variable,year,month,day=None,hour=None,
                       version='3.5.1',type='ensemble'):
    """Return the name of the file containing data for the
       requested variable, at the specified time, from the
       20CR version."""
    base_dir=get_data_dir(version)
    if variable == 'observations':
        if (day is None or hour is None):
            raise StandardError("Observation files names need day and hour")
        if hour%6!=0:
            raise StandardError("Observation files only available every 6 hours")
        name="%s/observations/%04d/prepbufrobs_assim_%04d%02d%02d%02d.txt" % (base_dir,
            year,year,month,day,hour)
        return name    
    if type in ('mean','spread','ensemble','normal',
                   'standard.deviation','first.guess.mean',
                   'first.guess.spread'):
        name="%s/%s" % (base_dir,type)
        if (type != 'normal' and type !='standard.deviation'):
            name="%s/%04d" % (name,year)
        name="%s/%s.nc" % (name,variable)
        return name
    raise StandardError("Unsupported type %s" % type)

def get_obs_1file(year,month,day,hour,version):
    """Retrieve all the observations for an individual assimilation run."""
    base_dir=get_data_dir(version)
    of_name=get_data_file_name('observations',year,month,day,hour,version)
    if not os.path.isfile(of_name):
        print version
        print "%04d-%02d-%02d:%02d" % (year,month,day,hour)
        raise IOError("No obs file for given version and date")

    o=pandas.read_fwf(of_name,
                       colspecs=[(0,19),(20,23),(24,25),(26,33),(34,40),(41,46),(47,52),
                                 (53,61),(60,67),(68,75),(76,83),(84,94),(95,100),
                                 (101,106),(107,108),(109,110),(111,112),(113,114),
                                 (115,116),(117,127),(128,138),(139,149),(150,160),
                                 (161,191),(192,206)],          
                       header=None,
                       encoding="ascii",
                       names=['UID','NCEP.Type','Variable','Longitude','Latitude',
                               'Elevation','Model.Elevation','Time.Offset',
                               'Pressure.after.bias.correction',
                               'Pressure.after.vertical.interpolation',
                               'SLP','Bias',
                               'Error.in.surface.pressure',
                               'Error.in.vertically.interpolated.pressure',
                               'Assimilation.indicator',
                               'Usability.check',
                               'QC.flag',
                               'Background.check',
                               'Buddy.check',
                               'Mean.first.guess.pressure.difference',
                               'First.guess.pressure.spread',
                               'Mean.analysis.pressure.difference',
                               'Analysis.pressure.spread',
                               'Name','ID'],
                       converters={'UID': str, 'NCEP.Type': int, 'Variable' : str,
                                   'Longitude': float,'Latitude': float,'Elevation': int,
                                   'Model.Elevation': int, 'Time.Offset': float,
                                   'Pressure.after.bias.correction': float,
                                   'Pressure.after.vertical.interpolation': float,
                                   'SLP': float,'Bias': float,
                                   'Error.in.surface.pressure': float,
                                   'Error.in.vertically.interpolated.pressure': float,
                                   'Assimilation.indicator': int,
                                   'Usability.check': int, 'QC.flag': int,
                                   'Background.check': int, 'Buddy.check': int,
                                   'Mean.first.guess.pressure.difference': float,
                                   'First.guess.pressure.spread': float,
                                   'Mean.analysis.pressure.difference': float,
                                   'Analysis.pressure.spread': float,
                                   'Name': str, 'ID': str},
                       na_values=['NA','*','***','*****','*******','**********',
                                          '-99','9999','-999','9999.99','10000.0',
                                          '-9.99',
                                          '999999999999','9'],
                       comment=None)
    return(o)

def compare_year(year):
    comp=[]
    cdate=datetime.datetime(year,1,1,0)
    while cdate<datetime.datetime(year+1,1,1,0):
        try:
            new_obs=get_obs_1file(cdate.year,cdate.month,cdate.day,cdate.hour,
                                  version='3.5.1')
            in_region=(new_obs['Longitude']>60) & (new_obs['Longitude']<160) &\
                      (new_obs['Latitude']>0)   & (new_obs['Latitude']<70)
            new_obs=new_obs[in_region]
            old_obs=get_obs_1file(cdate.year,cdate.month,cdate.day,cdate.hour,
                                  version='3.2.1')
            in_region=(old_obs['Longitude']>60) & (old_obs['Longitude']<160) &\
                      (old_obs['Latitude']>0)   & (old_obs['Latitude']<70)
            old_obs=old_obs[in_region]
            comp.append("%04d %04d %04d %s" % (len(new_obs['UID'])-len(old_obs['UID']),
                                               len(new_obs['UID']),len(old_obs['UID']),
                                               cdate.strftime("%Y-%m-%d:%H")))
        except IOError:
            print "Obs file missing"
            
        cdate=cdate+datetime.timedelta(hours=6)
    return sorted(comp,reverse=True)

for year in years:
    cy=compare_year(year)
    for idx in range(20):
        print cy[idx]
    print " "
