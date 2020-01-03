#!/usr/bin/env python

# For each month in 1836-2015, pick a random 1-degree longitude band
#  and get all the observations in that band for that month.

import datetime
import IRData.twcr as twcr
import pickle
import pandas
import numpy
import os
#import os.path

def next_month(dt0):
    dt1 = dt0.replace(day=1)
    dt2 = dt1 + datetime.timedelta(days=32)
    dt3 = dt2.replace(day=1)
    return dt3

obs=[]
for year in range(1836,2015):
    for month in range(1,13):
        fname= "%s/ISPD_poster/%04d/%02d.pkl" % (os.getenv('SCRATCH'),
                                                 year,month)
        if os.path.exists(fname): continue
        sdate = datetime.datetime(year,month,1,0,0)
        edate = next_month(sdate)
        m_ob = twcr.load_observations(sdate,edate,version='3')
        rand_l = numpy.random.randint(0,360)
        longs=numpy.array(m_ob['Longitude'])
        lats=numpy.array(m_ob['Latitude'])
        w=((numpy.isfinite(longs)) & (numpy.isfinite(lats)) &
                    (longs>=rand_l) & (longs <(rand_l+1)) &
                    (lats>=-90) & (lats <=90))
        s_ob = m_ob[w]
        fname= "%s/ISPD_poster/%04d/%02d.pkl" % (os.getenv('SCRATCH'),
                                                 year,month)
        if not os.path.isdir(os.path.dirname(fname)):
            os.makedirs(os.path.dirname(fname))
        pickle.dump( s_ob, open( fname, "wb" ) )

        
