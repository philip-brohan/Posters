#!/usr/bin/env python

# Take two images, and make a series of images interpolating
#  between them to provide a dissolve transition.

import os, numpy, PIL
from PIL import Image

import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--startfile",
                    type=str,required=True)
parser.add_argument("--endfile", 
                    type=str,required=True)
parser.add_argument("--n", help="No. of interpolating images",
                    type=int,default=12)
parser.add_argument("--opdir", help="Directory for files",
                    default="%s/images/EUSTACE_video" % \
                                           os.getenv('SCRATCH'),
                    type=str,required=False)
args = parser.parse_args()

startarr=numpy.array(Image.open("%s/%s" % (args.opdir,args.startfile)),
                     dtype=numpy.float)
endarr=numpy.array(Image.open("%s/%s" % (args.opdir,args.endfile)),
                     dtype=numpy.float)

for i in range(args.n):
    weight=(i+0.5)/args.n
    intarr = endarr*weight+startarr*(1-weight)
    intarr=numpy.array(numpy.round(intarr),dtype=numpy.uint8)
    opfn = "%s/%s.int_%02d.png" % (args.opdir,args.endfile[0:-4],i)
    out=Image.fromarray(intarr,mode="RGBA")
    out.save(opfn)
