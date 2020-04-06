#!/usr/bin/env python

# Scripts to make a EUSTACE plot for a range of days

import os
import datetime

start = datetime.date(1850,1,1)
end   = datetime.date(2011,12,31)

current = start
count=0
while current<=end:
    opf = "%s/images/EUSTACE_video/%04d%02d%02d00.png" %\
                  (os.getenv('SCRATCH'),current.year,
                   current.month,current.day)
    if not os.path.isfile(opf):
        print("./temperature.py --year=%d --month=%d --day=%d" %
                (current.year,current.month,current.day))
    opf = "%s/images/EUSTACE_video/%04d%02d%02d12.png" %\
                  (os.getenv('SCRATCH'),current.year,
                   current.month,current.day)
    if not os.path.isfile(opf):
        print("./temperature_i.py --year=%d --month=%d --day=%d" %
                (current.year,current.month,current.day))
    current += datetime.timedelta(days=1)
    count = count+1
    if count>=100:
        count=0
        if current.month==2 and current.day==29:
            current += datetime.timedelta(days=1)
        current = datetime.date(current.year+10,current.month,current.day)
