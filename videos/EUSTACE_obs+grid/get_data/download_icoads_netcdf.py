#!/usr/bin/env python

# Download the ICOADS3 netCDF files from NODC for a 
#  specified period

import os
import datetime
import subprocess
import time

import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--startyear",
                    type=int,required=False,
                    default=1850)
parser.add_argument("--endyear",
                    type=int,required=False,
                    default=2015)
args = parser.parse_args()

base_url="https://data.nodc.noaa.gov/icoads/"

local_dir="%s/ICOADS3/netCDF/" % os.getenv('SCRATCH')

for year in range(args.startyear,args.endyear+1):
    decade=year-year%10
    for month in range(1,13):
        file_n= "ICOADS_R3.0.0_%04d-%02d.nc" % (year,month)
        remote = "%s/%04ds/%04ds/%s" % (base_url,decade,decade,file_n)
        local = "%s/%s" % (local_dir,file_n)
        if not os.path.exists(os.path.dirname(local)):
            os.makedirs(os.path.dirname(local))
        if not os.path.isfile(local):
            cmd="wget -O %s %s" % (local,remote)
            wg_retvalue=subprocess.call(cmd,shell=True)
            #time.sleep(5)
            if wg_retvalue!=0:
                raise Exception("Failed to retrieve data")

