#!/usr/bin/env python

# Make all the individual frames for a movie

import os
import subprocess
import datetime

# Where to put the output files
opdir="%s/slurm_output" % os.getenv('SCRATCH')
if not os.path.isdir(opdir):
    os.makedirs(opdir)

# Function to check if the job is already done for this timepoint
def is_done(year,month,day,hour):
    op_file_name=("%s/images/20CRv3_global_3var/" +
                  "%04d%02d%02d%02d%02d.png") % (
                            os.getenv('SCRATCH'),
                            year,month,day,int(hour),
                                        int(hour%1*60))
    if os.path.isfile(op_file_name):
        return True
    return False

f=open("run.txt","w+")

start_day=datetime.datetime(1903,  1,  1,  0)
end_day  =datetime.datetime(1903, 12, 31, 23)

current_day=start_day
while current_day<=end_day:
    if is_done(current_day.year,current_day.month,
                   current_day.day,current_day.hour+current_day.minute/60):
        current_day=current_day+datetime.timedelta(hours=1)
        continue
    cmd=("./20CRv3_3var.py --year=%d --month=%d " +
         "--day=%d --hour=%f "+
         "--pole_latitude=90 --pole_longitude=180 "+
         "--npg_longitude=0 "+
         "--zoom=1 "+
         "\n") % (
           current_day.year,current_day.month,
             current_day.day,current_day.hour+current_day.minute/60)
    f.write(cmd)
    current_day=current_day+datetime.timedelta(hours=1)
f.close()

