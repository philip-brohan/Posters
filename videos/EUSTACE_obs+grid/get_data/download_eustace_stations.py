#!/usr/bin/env python

# Download the daily EUSTACE1.0 station obs. from CEDA for a 
#  specified period.

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

base_url=("http://dap.ceda.ac.uk/thredds/fileServer/"+
          "neodc/eustace/data/station/ubern/land/global/"+
          "daily/v1.0")

local_dir="%s/EUSTACE/stations/" % os.getenv('SCRATCH')

for year in range(args.startyear,args.endyear+1):
    file_n= "eustace_stations_global_%04d_daily_temperature.nc" % year
    remote = "%s/%s" % (base_url,file_n)
    local = "%s/%s" % (local_dir,file_n)
    if not os.path.exists(os.path.dirname(local)):
        os.makedirs(os.path.dirname(local))
    if not os.path.isfile(local):
        cmd="wget -O %s %s" % (local,remote)
        wg_retvalue=subprocess.call(cmd,shell=True)
        #time.sleep(5)
        if wg_retvalue!=0:
            raise Exception("Failed to retrieve data")

