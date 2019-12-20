#!/usr/bin/env python

# Retrieve all the v3 observations files from NERSC

import datetime
import IRData.twcr as twcr

for year in range(1851,2016):
    twcr.fetch('observations',datetime.datetime(year,1,1),version='3')
