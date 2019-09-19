#!/usr/bin/env python

# Retrieve MO global model surface temperature data from mass

import IRData.opfc as opfc
import datetime

for year in [2016,2017]:
    for month in range(12):
        opfc.fetch('tsurf',datetime.datetime(year,month+1,15))
