#!/usr/bin/env python

# Fill in the gaps in the frame list with dissolve transitions.

import os
import datetime
import glob

files = sorted(glob.glob("%s/images/EUSTACE_video/[0-9]*.png" % 
                                      (os.getenv('SCRATCH'))))

for idx in range(len(files)-1):
    f1 = os.path.basename(files[idx])
    f2 = os.path.basename(files[idx+1])
    d1 = datetime.datetime(int(f1[0:4]),int(f1[4:6]),
                           int(f1[6:8]),int(f1[8:10]))
    d2 = datetime.datetime(int(f2[0:4]),int(f2[4:6]),
                           int(f2[6:8]),int(f2[8:10]))
    if (d2-d1).total_seconds() > 864000:
        print(("./make_dissolve_transition.py --startfile=%s "+
               "--endfile=%s") % (f1,f2))

