#!/usr/bin/env python

# Download boundary conditions.
# Store it on $SCRATCH

import os
import urllib.request

# Land mask
srce=("https://s3-eu-west-1.amazonaws.com/"+
      "philip.brohan.org.big-files/fixed_fields/"+
      "land_mask/opfc_global_2019.nc")
dst="%s/fixed_fields/land_mask/opfc_global_2019.nc" % os.getenv('SCRATCH')
if not os.path.exists(dst):
    if not os.path.isdir(os.path.dirname(dst)):
        os.makedirs(os.path.dirname(dst))
    urllib.request.urlretrieve(srce, dst)
# Orography
srce=("https://s3-eu-west-1.amazonaws.com/"+
      "philip.brohan.org.big-files/fixed_fields/"+
      "orography/opfc_global_2019.nc")
dst="%s/fixed_fields/orography/opfc_global_2019.nc" % os.getenv('SCRATCH')
if not os.path.exists(dst):
    if not os.path.isdir(os.path.dirname(dst)):
        os.makedirs(os.path.dirname(dst))
    urllib.request.urlretrieve(srce, dst)

