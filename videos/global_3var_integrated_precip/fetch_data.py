#!/usr/bin/env python

# Retrieve MO global model surface temperature data from mass

import IRData.opfc as opfc
import datetime

for year in [2018,2018]:
    for month in (12,11,10,9,8,7,6,5,4):
#        if year==2016 and month<6: continue
        opfc.fetch('tsurf',datetime.datetime(year,month,15))
